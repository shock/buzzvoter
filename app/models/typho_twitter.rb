# Note the tests at the bottom.  You can test this class by running it standalone in the interpreter.

require 'rubygems'
require "cgi"
require "net/http"
require "uri"
require "time"
require "typhoeus"
require "pp"
require 'json'
require 'base64'

if $0 == __FILE__
  require '../../lib/app_common'
else
  require 'app_common'
end

# Class to abstract access to Twitter's Web Traffic API.
# Makes use of the Typhoeus gem to enable concurrent API calls.

class TyphoTwitter
  
  def puts message
    Kernel.puts message
  end
  
  class HTTPException < RuntimeError
    attr :code
    attr :body
    
    def initialize( code, body )
      @code = code
      @body = body
      super( "#{code} - #{body}" )
    end
  end
  
  ##############################################################
  # TYPHOEUS STUFF
  #

    include Typhoeus
    remote_defaults :on_success => lambda { |response| #puts "TWITTER - Success"; 
                                            response.body },
                    :on_failure => lambda { |response| puts "TWITTER - ERROR #{response.code}"; 
                                            raise HTTPException.new( response.code, response.body ) },
                    :base_uri   => "http://twitter.com/users/show.json"
    # Typhoeus HTTP call declaration, creates a static method on this class called users_records()
    define_remote_method :users_records

  #
  # TYPHOEUS STUFF
  ##############################################################
  
  def initialize
    # raise RuntimeError.new("Instantiation of class TyphoTwitter not allowed.  All methods are static.")
  end
  
  TWITTER_THROTTLE_LIMIT = 100  # TyphoTwitter throttles HTTP requests to 20 per second per IP
  TWITTER_THROTTLE_TIMEOUT = 1.1   #
  # Retrieves the user data for a group of user_ids from Twitter.
  # user_id_array = An array twitter user ids, one for each user to get data for
  # Returns a Hash of objects from Twitter
  def get_users_records user_id_array, login='buzzvoter', password='otherinbox2008'
    users_records = {}
    typho_slice_size = TWITTER_THROTTLE_LIMIT # total number of users we can lookup per Typhoeus batch
    retries = 10
    b64_encoded = Base64.b64encode("#{login}:#{password}")
    headers = {"Authorization" => "Basic #{b64_encoded}"}
    @time_gate = TimeGate.new
    while user_id_array.length > 0 && retries > 0
      failed_user_ids = []
      typho_slice_index = 0
      while typho_slice_index < user_id_array.length
        puts "Getting user_ids #{typho_slice_index}-#{typho_slice_index + typho_slice_size}"
        user_id_array_slice = user_id_array.slice(typho_slice_index, typho_slice_size)
        twitter_calls = []
        
        user_id_array_slice.each do |user_id| 
          path = "?id=#{user_id}"
          twitter_calls << TyphoTwitter.users_records( :path=>path, :headers=>headers )
        end
        
        index = 0
        @time_gate.wait
        twitter_calls.each do |json_result|
        user_id = user_id_array[typho_slice_index + index]
          begin
            json_result_object = JSON.parse( json_result ) 
            # puts json_result
            users_records[user_id] = json_result_object
          rescue JSON::ParserError
            puts json_result
            puts "TWITTER: #{$!.inspect}"
            failed_user_ids << user_id
          rescue HTTPException => e
            case e.code
            when 404:
              puts "Skipping unknown user_id: #{user_id}"
            when 502:
              puts "TyphoTwitter Over capacity for user_id: #{user_id}.  Will retry."
              failed_user_ids << user_id
            else
              puts "Unexpected HTTP result code: #{e.code}"
              failed_user_ids << user_id
            end
          ensure
            index += 1
          end
        end
        @time_gate.set 1
        typho_slice_index += typho_slice_size
      end
      user_id_array = failed_user_ids
      retries -= 1
    end
    if failed_user_ids
      failed_user_ids.each do |user_id|
        users_records[user_id] = 0  # TODO return something more meaningful
      end
    end
    users_records
  end  
end


# Standalone testing:
if $0 == __FILE__
  
  # basic test that all is functioning and that we can lookup an array of user_ids successfully
  def test1
    user_ids = [ 
      "bdoughty", 
      "joshuabaer", 
      "jotto", 
      "hoonpark", 
      "aplusk", 
      "barackobama", 
      "oprah"
      ]
    user_ids= [
      "34757139",
      "6082719",
      "539139",
      "69632",
      "2402814"
    ]
    user_id_array = user_ids
    # 10.times do |i|
    #   user_id_array += user_ids.map{|c| c+i}
    # end
    twitter = TyphoTwitter.new
    responses = twitter.get_users_records user_id_array
    responses.each do |key, value|
      puts "#{key} => "
      puts "#{value}"
    end
    puts "# Responses: #{responses.size}"
    if responses.size != user_id_array.size
      # raise RuntimeError.new("Expected #{user_id_array.size} results but got #{responses.size} instead." )
    end
  end
  
  # Verify that things still function correctly if we are only looking up one user.
  def test2
    user_ids = [ 
      "bdoughty"
      ]
    user_id_array = user_ids
    # user_id_array += user_ids
    twitter = TyphoTwitter.new
    responses = twitter.get_users_records user_id_array
    responses.each do |key, value|
      puts "#{key} => "
      puts "#{value}"
    end
    puts "# Responses: #{responses.size}"
    if responses.size != user_id_array.size
      raise RuntimeError.new("Expected #{user_id_array.size} results but got #{responses.size} instead." )
    end
  end
  

  # Test that we successfully discriminate TyphoTwitter's response for sub-domains and set the results accordingly
  # blogsearch and news should have distinct results (at least highly unlikely they wouldn't!)
  # This test also includes some domains that were problematic during testing.
  def test4
    user_ids = [ 
      1650013,
      6082719,
      539139,
      69632,
      2402814
      ]
    user_id_array = user_ids
    # user_id_array += user_ids
    twitter = TyphoTwitter.new
    responses = twitter.get_users_records user_id_array
    responses.each do |key, value|
      puts "#{key} => "
      puts "#{value}"
    end
    puts "# Responses: #{responses.size}"
    if responses.size != user_id_array.size
      raise RuntimeError.new("Expected #{user_id_array.size} results but got #{responses.size} instead." )
    end
  end
  
  # Test that the New York times yields a 10.0 weight.
  def test5
    user_ids = [ 
      "http://huffingtonpost.com/",
      "http://nytimes.com/"
      ]
    user_id_array = user_ids
    # user_id_array += user_ids
    twitter = TyphoTwitter.new
    responses = twitter.get_users_records user_id_array
    responses.each do |key, value|
      puts "#{key} => "
      puts "#{value}"
    end
    puts "# Responses: #{responses.size}"
    if responses.size != user_id_array.size
      raise RuntimeError.new("Expected #{user_id_array.size} results but got #{responses.size} instead." )
    end
    nyt_resp = responses["http://nytimes.com/"]
    if (nyt_resp.weight - 10.0).abs > 0.1
      raise RuntimeError.new("Expected New York Times weight to be close to 10.0, but it was #{nyt_resp.weight}. To fix this, set BUZZ_SCALAR to #{nyt_resp.reach/10.0}" )
    end
  end
  
  # test1
  
  # test2
  
  # test3
  
  # test4
  def run_tests
    if ARGV[0] && ARGV[0] != ""
      eval ARGV[0]
    else
      test1
      test2
      # test3
      # test4
      # test5
    end
  end
  
  run_tests
  # test5

end


