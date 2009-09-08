class Poll < ActiveRecord::Base
  belongs_to :user
  has_many :votes, :dependent=>:destroy

  named_scope :recent, lambda { |limit| 
    limit ||= 5
      {:conditions => "", :limit=>limit, :order=>"created_at DESC"} 
  }
  
  named_scope :active, :conditions =>"ending_time > \"#{Time.now.utc.to_s(:db)}\""
  
  validates_presence_of :answers, :url, :poll_tag
  validates_uniqueness_of :url, :poll_tag
  
  TEST_MODE = false
  
  private
  
  def logger
    # puts "@logger #{@logger.inspect}"
    @logger || RAILS_DEFAULT_LOGGER
  end

  class AnswerValidationError < RuntimeError; end
  class InvalidVoteError < RuntimeError; end
  
  def self.get_answers_from_form_fields answers, abbrs
    puts "answers: #{answers.inspect}"
    puts "abbrs: #{abbrs.inspect}"
    answers_hash = {}
    answers.each do |answer_name|
      abbr = abbrs.shift
      if answer_name.blank? || abbr.blank?
        raise AnswerValidationError.new( "Answer and Abbreviation fields cannot be blank." );
      elsif !(abbr =~ /^\w*$/)
        raise AnswerValidationError.new( "Abbreviation fields must contain alpha-numeric characters only with no spaces." );
      elsif answer_name =~ /\|/ || abbr =~ /\|/
        raise AnswerValidationError.new( "Answers cannot contain the '|' character." );
      elsif answers_hash.keys.include?( abbr )
        raise AnswerValidationError.new( "Answer abbreviations must be unique." );
      else
        answers_hash[abbr] = {:name=>answer_name, :votes=>0, :abbr=>abbr}
      end
    end
    answer_column = answers_hash.to_yaml
  end
  
  # Sends a response tweet to the voter when a valid vote is recieved
  def send_vote_reply vote
    tweeter = Tweeter.default
    reply_text = reply_message.gsub('#ANSWER#', "##{vote.answer_abbr}").gsub('#POLLNAME#', name )
    status = "@#{vote.voter_name} #{reply_text} #{fq_url} #{poll_tag}"
    tweeter.status_update( status, vote.tweet_id )
    logger.info("REPLY SENT")
  end
  
  # Sends a tweet to the voter with the current poll results
  def send_poll_results vote
    tweeter = Tweeter.default
    _winners = winners
    if _winners.length > 1
      status = "@#{vote.voter_name} The current winners in the #{name} poll are #{winners_as_text}. #{fq_url} #{poll_tag}"
    else
      status = "@#{vote.voter_name} The current winner in the #{name} poll is #{winners_as_text}. #{fq_url} #{poll_tag}"
    end
    tweeter.status_update( status, vote.tweet_id )
    logger.info("POLL RESULTS SENT")
  end
  
  # Sends a tweet to the voter with an error message
  def send_error_reply tweet, message
    tweeter = Tweeter.default
    status = "@#{tweet.from_user} Sorry. Your vote was rejected. #{message}"
    tweeter.status_update( status, tweet.tweet_id )
    logger.info("ERROR MESSAGE SENT")
  end
  
  # creates a Vote record from the tweet.  returns an InvalidVote exception if the vote is invalid
  def create_vote_from_tweet tweet
    begin
      valid = false
      # see if the user already has made a valid vote
      valid_vote = Vote.find_by_voter_id_and_poll_id_and_is_valid(tweet.from_user_id, id, true)
      raise InvalidVoteError.new("One vote allowed per poll.") if valid_vote
      answer_abbr = nil
      abbreviations.each do |abbr|
        # puts "tweet.text #{tweet.text}"
        # puts "abbr #{abbr}"
        if tweet.text =~ /##{abbr}/
          raise InvalidVoteError.new("It contains more than one valid answer.") if answer_abbr
          answer_abbr = abbr
        end
      end
      if answer_abbr
        valid = true
      else
        raise InvalidVoteError.new("It does not contain a valid answer.")
      end
    rescue Exception
      raise $!
    ensure
      vote = Vote.create!( :poll_id=>id, :answer_abbr=>answer_abbr, :tweet_id=>tweet.tweet_id, :voter_id=>tweet.from_user_id, :voter_name=>tweet.from_user, :text=>tweet.text, :profile_image_url=>tweet.profile_image_url, :to_user_id=>tweet.to_user_id, :tweet_created_at=>tweet.created_at, :is_valid=>valid )
    end
    vote
  end
  
  # processes an individual search result, and creates a vote if applicable
  def process_result tweet
    @total_results += 1
    
    begin
      # return right away if we have already processed this tweet
      return if Vote.find_by_tweet_id( tweet.tweet_id )
      vote = create_vote_from_tweet(tweet)
      send_vote_reply( vote )
      send_poll_results( vote ) if results_reply
      @new_results += 1

    rescue InvalidVoteError
      send_error_reply( tweet, $!.to_s )
      # The users vote is invalid.  TODO: send a tweet back to them indicating the error.
      logger.info "** Invalid Vote: #{$!.inspect}"
      logger.info "** Vote Contents: #{tweet.inspect}"
    rescue ActiveRecord::StatementInvalid
      if $!.to_s =~ /Mysql::Error: Duplicate entry/
        begin
          Mailer.deliver_exception_notification $!, "Vote must have been created by another thread."
        rescue Errno::ECONNREFUSED
          logger.error( "Could not connect to mail server.")
        end              
      end
    end
  end
  
  # get the poll results from Twitter
  def get_results
    
    stories = []
    blog_posts = [] 
    tweets = []
    base_errors = []
    last_date = nil
    
    # searchterms = search_terms.gsub(" and ", " ").gsub("\r", "").split("\n").collect{|s| "("+s+")"}.join( " OR " )
    terms_set = search_terms.split("\n")
    
    start_time = Time.zone.now
    @total_results = 0
    @new_results = 0
    update_attributes!( :last_started => Time.zone.now, :status=>"executing", :seconds_to_execute=>nil, :total_results=>nil, :new_results=>nil )
    
    terms_set.each do |terms|
      next if terms.strip.blank?
      procs = []
      @second_phase_topic_post_queue = Queue.new  # Use Queue to ensure thread safety.

      if( true )
        twitter_proc = Proc.new do
          begin
            logger.info( "Searching Twitter with #{terms} : #{DateTime.now.ltf}" ) 
            searcher = TS.new( terms, nil, last_date, nil, 0, $APP_CONFIG[:search][:ts_debug_level] )
            _tweets = []
            while( !TEST_MODE && tweet = searcher.next_result )
              _tweets << tweet
              # puts "tweet: #{tweet.inspect}"
              # debug_msg( tweet.to_s, 2 )
              process_result tweet
            end
            logger.info( "Twitter (#{terms}) results: #{_tweets.length} : #{DateTime.now.ltf}" )
          end
        end
        procs << twitter_proc
      end

      begin
        threading = $APP_CONFIG[:search][:use_threading]
        if( threading )
          # puts("Executing search in multi-threaded mode.")
          threads = []
          procs.each do |proc|
            thread = Thread.new(proc, Thread.current) do |search_proc, caller_thread|
              begin
                Poll.connection.reconnect!
                search_proc.call
              rescue Exception
                Thread.current[:exception] = $!
              end
            end
            threads << thread
          end
          # debug_msg "Waiting on Threads " + threads.join(" ")
          threads.each do |thread| 
            thread.join
            if thread[:exception]
              raise thread[:exception]
            end
          end
          # debug_msg "Passed wait on Threads"
        else
          # puts("Executing search in single-threaded mode.")
          procs.each do |proc|
            proc.call
          end
        end

      rescue Exception => exception
        logger.error $!.inspect
        logger.error $!.backtrace.join("\n")
        raise $!
      end
    end
    update_attributes!( :last_updated => Time.zone.now, :status=>"completed", :seconds_to_execute=>Time.zone.now-start_time, :total_results=>@total_results, :new_results=>@new_results )
  end
  
  public
  
  # generates the proper Twitter search terms for this poll
  def search_terms
    "#vote #{poll_tag}"
  end

  def execute _logger=RAILS_DEFAULT_LOGGER
    @logger = _logger
    search = self
    logger.info "\nEXECUTING POLL SEARCH ID: #{search.id} - #{Time.zone.now.ltf} LAST UPDATED: #{search.last_updated ? search.last_updated.ltf : "Never"}"
    searchterms = search.search_terms.downcase.gsub(" and ", " ").gsub("\r", "").split("\n").collect{|s| "("+s+")"}.join( " OR " )
    logger.info "Combined Search Terms: #{searchterms}"
    search_start_time = DateTime.now
    begin
      get_results
      logger.info("NEW RESULTS: #{search.new_results}  TOTAL RESULTS: #{search.total_results}")
    rescue SystemExit
      raise $!
    rescue Exception => exception
      attributes = {:status=>"failed"}
      search.update_attributes!( attributes )
      begin
        error_message = "------------------------\n" +
          "EXCEPTION: #{exception.inspect}\n" +
          "POLL ID: #{search.id}\n" +
          "SEARCH TERMS: #{searchterms}\n"
        logger.error error_message
        logger.error exception.backtrace.join("\n")
        Mailer.deliver_exception_notification exception, error_message, "no user"
      rescue Exception => e
        begin
          logger.error "EXCEPTION delivering exception notification mail: #{exception.class} - #{e}"
          logger.error e.backtrace.join("\n")
        rescue Exception
          puts "*************** ******************* Failed to even log exception."
        end
      end
    end
        
    search_end_time = DateTime.now
    hours, minutes, seconds, fractions = Date.day_fraction_to_time(search_end_time-search_start_time)
    logger.info "POLL #{search.status.to_s.upcase} in #{minutes + hours*60} mins #{seconds} secs"
  end  
  
  # Function to generate a unique URL.  TODO: optimize to create a shorter string.
  def self.create_unique_url
    url = Time.now.utc.strftime("%y%j%H%M%S")
  end
  
  # creates a new poll from the supplied form fields
  def self.new_from_form_fields params
    answer_names = params.delete(:answer_names)
    answer_abbrs = params.delete(:answer_abbrs)
    poll = Poll.new( params )
    begin
      poll.answers = get_answers_from_form_fields( answer_names, answer_abbrs )
    rescue AnswerValidationError
      poll.errors.add( :answer, $!.to_s )
    end
    poll
  end

  # updates a poll from the supplied form fields
  def update_from_form_fields params
    answer_names = params.delete(:answer_names)
    answer_abbrs = params.delete(:answer_abbrs)
    begin
      params[:answers] = Poll.get_answers_from_form_fields( answer_names, answer_abbrs )
    rescue AnswerValidationError
      return false
    end
    update_attributes(params)
  end
  
  def answers_hash
    answer_hash = YAML.load(self[:answers])
  end
    
  # returns a one dimensional array of all the answers' abbreviations
  def abbreviations
    answers_hash.keys
  end
  
  def active
    ending_time > Time.now.utc
  end
  
  alias :active? :active
  
  def self.find_by_id_or_url id_or_url
    begin
      poll = Poll.find(id_or_url)
    rescue ActiveRecord::RecordNotFound
      poll = Poll.find_by_url(id_or_url)
    end
  end
  
  def get_answers_with_votes
    @answer_records = answers_hash.values
    @total_votes = total_votes
    @answer_records.each do |answer_record|
      answer_record[:votes] = Vote.find_all_by_answer_abbr_and_poll_id_and_is_valid( answer_record[:abbr], id, true )
      answer_record[:num_votes] = answer_record[:votes].length
      if @total_votes > 0
        answer_record[:percentage] = '%0.f%' % (answer_record[:num_votes].to_f / @total_votes.to_f * 100.0)
      else
        answer_record[:percentage] = '0%'
      end
    end
    @answer_records.sort{ |a,b| b[:num_votes] <=> a[:num_votes]}
  end
  
  def total_votes
    @total_votes = Vote.count(:conditions=>{:poll_id=>id, :is_valid=>true})
  end
  
  def fq_url
    "#{$APP_CONFIG.site_url}/#{url}"
  end
  
  # returns an array of answer_records, one for each first place winner
  # returns an empty array if there are no votes yet
  def winners
    answer_records = get_answers_with_votes
    _winners = []
    first = answer_records.shift
    if first[:num_votes] > 0
      _winners << first
      answer_records.each do |answer_record|
        _winners << answer_record if answer_record[:num_votes] == first[:num_votes]
      end
    end
    _winners
  end
  
  def winners_as_text separator=", ", conjunction=" and "
    _winners = winners
    if _winners.length == 0
      output = "No votes yet."
    else
      output = "#{_winners.shift[:name]}"
      _winners.each do |winner|
        if winner != _winners.last
          output +="#{separator}#{winner[:name]}"
        else
          output +="#{conjunction}#{winner[:name]}"
        end
      end
    end
    output
  end
  
  def generated_vote_tweet
    tweet = vote_tweet.gsub('#POLLNAME#', name ).gsub('#POLLTAG#', poll_tag ).gsub('#URL#', fq_url )
  end
end
