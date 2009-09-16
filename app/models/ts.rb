require 'uri'
require 'simpledebug'
require 'rubygems'
require 'grackle'

class TS
  include SimpleDebug
  
  NUM_RETRIES = 10

  # Exceptions
  class TSException < RuntimeError; end
  class NoResultsException < TSException; end
  class FetchException < TSException; end
  class ParseException < TSException; end

  class Tweet    

    def initialize result
      @result = result
    end
    
    def method_missing method_id, *args
      @result.send method_id, *args
    end
    
    def created_at
      DateTime.parse @result.created_at
    end
    
    def to_s
      @result.inspect
    end
  end

  public

  def getTweetsForPage page
    debug_msg("Search page #{page}", 2)
    successful = false
    retries = NUM_RETRIES
    while !successful && retries > 0
      begin
        query = @grackle[:search].search? :q=>@search_terms, :rpp=>100, :page=>@page
        successful = true
      rescue Grackle::TwitterError
        error_msg( $!.to_s + "\nRetrying.  #{retries} tries left." )
        retries -= 1
        if retries == 0
          raise $!
        end
        sleep (NUM_RETRIES - retries)
      end
    end
    results = query.results
    @page_results = []
    results.each do |result|
      tweet = Tweet.new(result)
      debug_msg "Tweet: #{tweet.inspect}", 5
      @page_results << tweet
    end
    @more_pages = (query.next_page != nil)
    @page_results
  end

  def getNextResultsPage
    if( !@more_pages )
      debug_msg( "Twitter Search: getNextResultsPage(): no more pages", 1 )
      return nil
    end
    @error = false
    debug_msg( "Searching Twitter with terms: #{@search_terms}", 0 )
    debug_msg( "Max Results: #{@max_results}, Min Date: #{@min_date.to_s}", 2 )

    # start by getting the first page is will help us know how many total results to expect
    # There are 10 results per page   (WDD 3/13/09)
    begin
      debug_msg( "Twitter: Getting 100 results...", 1 )
      @page_results = getTweetsForPage( @page )
      debug_msg( "#{@page_results.length} results found.", 1 )
    rescue NoResultsException
      debug_msg "NO RESULTS!"
      return []
    rescue FetchException
      @error = true
      error_msg( "Error fetching results for: #{@search_terms}" )
      error_msg( $! )
      return []
    rescue Net::HTTPServiceUnavailable
      @error = true
      error_msg( "Error fetching results for: #{@search_terms}" )
      error_msg( $! )
      return []
    end
    #pp page_resp

    @page += 1

    #debug_msg from.to_s + " " + to.to_s + " " + max.to_s

  end

  def getNextResult
    debug_msg( "Attempting to get next result...", 3 )
    if( !@page_results )
      getNextResultsPage()
    elsif( @page_results.length == 0 )
      if( @max_results )
        if( @num_elements < @max_results )
          getNextResultsPage()
        else
          return nil
        end
      else
        getNextResultsPage()
      end
    end
    result = nil
    if( @page_results )
      debug_msg("Page Results: TRUE", 5)
      result = @page_results.shift
      if( result )
        debug_msg("Next Result: TRUE", 5)
        # check the last result to see if it is within the date range
        if( result.created_at < @min_date )
          debug_msg("Skipping Tweet too old.", 5)
          result = nil
        else
          @num_elements += 1
        end
      end
    end
    result
  end

  public

  def initialize( search_terms, max_results=nil, min_date=nil, max_date=nil, bot_delay_secs = 0, debug_level = -1 )
    setDebugPrefix( "TS: " )
    @search_terms = search_terms
    @max_results = max_results
    @min_date = min_date
    if( !@min_date )
      @min_date = Time.now.utc - 30.days
    end
    @search_terms += " since:" + @min_date.strftime( "%Y-%m-%d" )
    @max_date = max_date
    @bot_delay_secs = bot_delay_secs
    setDebugLevel debug_level
    @story_elements=[]
    @num_elements = 0
    @page = 1
    @max = nil
    @previous_last_href = ""
    @page_results = nil
    @grackle = Grackle::Client.new(:username=>'buzzmanager_api',:password=>'otherinbox2008')
    @more_pages = true
  end

  def next_result
    getNextResult
  end

end

def test
  ts = TS.new("otherinbox", nil, nil, nil, 0, 5 )
  while result = ts.next_result
    puts result.to_s
  end
end

if $0 == __FILE__
  test
end
