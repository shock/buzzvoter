# Class to enscapsulate functions for sending a Tweet.
require 'net/http'
require 'rubygems'
require 'json'

class Tweeter
  
  private
  
  def update( text, in_reply_to_status_id=nil )
    http = Net::HTTP.new('twitter.com', 80)
    json_data = http.start do |http_inst|
      path = "/statuses/update.json"
      req = Net::HTTP::Post.new( path )
      
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth @login, @password
      if in_reply_to_status_id
        req.set_form_data({'status'=>text, 'in_reply_to_status_id'=>"#{in_reply_to_status_id}"})
      else
        req.set_form_data({'status'=>text})
      end
      resp, data = http_inst.request(req)
      data
    end
    hash_data = JSON.parse( json_data )
  end

  public
  
  def self.default
    Tweeter.new( $APP_CONFIG[:twitter][:login], $APP_CONFIG[:twitter][:password] )
  end
  
  def status_update( text, in_reply_to_status_id=nil )
    update( text, in_reply_to_status_id )
  end
  
  def initialize( login, password )
    @login = login
    @password = password
  end
end

if $0 == __FILE__
  tweeter = Tweeter.new( 'buzzvoter', 'otherinbox2008' )
  hash = tweeter.status_update("Hello.")
  puts hash.inspect
end