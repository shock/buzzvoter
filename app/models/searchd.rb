if !defined? SEARCHD
  SEARCHD = true
  RAILS_ROOT = File.expand_path( File.dirname(__FILE__) + "/../.." )
  ENV["RAILS_ENV"] ||= "development"
  require(File.join(RAILS_ROOT, 'config', 'boot'))
  require(File.join(RAILS_ROOT, 'config', 'environment'))

  require 'app_common'
  require 'ruby_extensions'

  logfile = File.open(RAILS_ROOT+"/log/searchd_#{ENV['RAILS_ENV']}.log", 'a')
  logfile.sync = true
  logger = Logger.new(logfile)
  logger.level = Logger::Severity::INFO
  RAILS_DEFAULT_LOGGER = logger

  class SearchDaemon
    # include SimpleDebug
    
    private
  
    def logger
      @search_logger
    end
  
    def update_log_header no_searches_this_pass
      if no_searches_this_pass
        logger.info ""
        logger.info "======================================================"
        logger.info "= Beginning Cycle: #{Time.zone.now.ltf}"
      end
      false
    end
  
    def update_log_footer no_searches_this_pass, delta_time
      unless no_searches_this_pass
        hours, minutes, seconds, fractions = Date.day_fraction_to_time(delta_time)
        logger.info ""
        logger.info "= Cycle Completed in #{minutes + hours*60} mins #{seconds} secs - #{Time.zone.now.ltf}"
        logger.info "======================================================"
      end
    end
    public
  
    def main
      logger.info ""
      logger.info ""
      logger.info "========================================================================="
      logger.info "========================================================================="
      logger.info "========================================================================="
      logger.info "SEARCH DAEMON STARTING @ #{Time.zone.now.ltf}"
      logger.info "Multi-threading enabled: #{$APP_CONFIG[:search][:use_threading]}"
      logger.info ""
      RAILS_DEFAULT_LOGGER.info $APP_CONFIG.to_s
      Poll.update_all("status = 'none'", "status = 'executing'")

      # Create a dummay last search that won't fail the critical tests

      loop do
        begin
          while ( @cycle_time_gate.wait( false ) && @should_execute ) do sleep 0.2; end
          @cycle_time_gate.set $APP_CONFIG[:search][:polling_interval_s]  # minimum delay between polling for new jobs
          start_time = DateTime.now
          break if !@should_execute 
          no_searches_this_pass = true
        
          # logger.info "Checking for active Polls..."
          auto_searches = Poll.active.all(:conditions=>"status != 'executing'", :order=>:last_updated)
          auto_searches.each do |auto_search|
            logger.info "ACTIVE SEARCH: #{auto_search.name}:#{auto_search.id} - ENDING: #{auto_search.ending_time}"
          end
          # puts "auto_searches: #{auto_searches.inspect}"
          skipped_search = nil
          # Then loop through them until we find one that is ready for processing
          while @should_execute && auto_search = auto_searches.shift
            # puts "auto_search: #{auto_search.inspect}"
            if (!auto_search.last_updated || auto_search.last_updated < Time.zone.now - $APP_CONFIG[:search][:minimum_search_interval_s].seconds)  && (!auto_search.last_started || auto_search.last_started < Time.zone.now - $APP_CONFIG[:search][:minimum_search_interval_s].seconds)
              no_searches_this_pass = update_log_header no_searches_this_pass
              auto_search.execute( @search_logger )
              last_search = auto_search
            end
          end
          
          # Now check for unprocessed, finished Polls and process them
          unprocessed_polls = Poll.unprocessed.all
          while @should_execute && next_poll = unprocessed_polls.shift
            next_poll.process
          end
          end_time = DateTime.now
          delta_time = end_time - start_time
          update_log_footer no_searches_this_pass, delta_time
        rescue SystemExit
          logger.info "EXPLICIT CALL to exit() from #{$!.backtrace[0]}"
          logger.info "EXITING MAIN LOOP"
          @should_execute = false
        rescue Exception => exception
          begin
            logger.error "Search Daemon Exception: #{exception.inspect}"
            logger.error exception.backtrace.join("\n")
            Mailer.deliver_exception_notification exception, "Search Daemon Exception", "no user"
          rescue Exception => e
            begin
              logger.error "EXCEPTION delivering exception notification mail: #{exception.class} - #{e}"
              logger.error e.backtrace.join("\n")
            rescue Exception
              puts "*************** ******************* Failed to even log exception."
            end
          end
        ensure
        end
      end
      logger.info ""
      logger.info ""
      logger.info "SEARCH DAEMON SHUTTING DOWN @ #{Time.zone.now.ltf}"
      logger.info "========================================================================="
    end
  
    def install_interrupt_handlers
      # Trap the signals that would terminate the SearchDaemon so we can hopefully avoid dying whilst
      # happening to be in the middle of a search.
      # We will be proper and make sure to chain to the previous signal handlers.
      @previous_SIGINT_handler = Kernel.trap( "SIGINT" ) {}
      Kernel.trap( "SIGINT" ) { 
        self.stop; 
        if @previous_SIGINT_handler != "DEFAULT"
          @previous_SIGINT_handler.call
        end
        Kernel.trap( "SIGINT" ) { @main_thread.raise(SystemExit.new) }
      }
      @previous_SIGQUIT_handler = Kernel.trap( "SIGQUIT" ) {}
      Kernel.trap( "SIGQUIT" ) { 
        self.stop; 
        if @previous_SIGQUIT_handler != "DEFAULT"
          @previous_SIGQUIT_handler.call
        end
        Kernel.trap( "SIGQUIT" ) { @main_thread.raise(SystemExit.new) }
      }
      @previous_SIGTERM_handler = Kernel.trap( "SIGTERM" ) {}
      Kernel.trap( "SIGTERM" ) { 
        self.stop; 
        if @previous_SIGTERM_handler != "DEFAULT"
          @previous_SIGTERM_handler.call
        end
        Kernel.trap( "SIGTERM" ) { @main_thread.raise(SystemExit.new) }
      } 
      @previous_SIGUSR1_handler = Kernel.trap( "SIGUSR1" ) {}
      Kernel.trap( "SIGUSR1" ) { 
        self.stop; 
        if @previous_SIGUSR1_handler != "DEFAULT"
          @previous_SIGUSR1_handler.call
        end
        Kernel.trap( "SIGUSR1" ) { @main_thread.raise(SystemExit.new) }
      }
    end
  
    def start
      @should_execute = true
      install_interrupt_handlers
      @main_thread = Thread.new do
        main
      end
    end
  
    def stop
      logger.info ""
      logger.info "STOP REQUEST RECEIVED"
      logger.info "SERVER WILL HALT AFTER LAST SEARCH FINISHES"
      @should_execute = false
    end
  
    def initialize search_logger
      @search_logger = search_logger
      @cycle_time_gate = TimeGate.new
    end
  
    def self.init standalone
      search_daemon = SearchDaemon.new RAILS_DEFAULT_LOGGER
      search_deamon_thread = search_daemon.start
      # SinatraServer.new( search_daemon ) if standalone
      search_deamon_thread.join if standalone
    end
  
    class SinatraServer
      require 'sinatra'
      disable :run

      attr :sinatra_thread

      def initialize search_daemon
        get "/" do
                output = <<-TXT
                <form method=post action="/#{params[:topic_id]}">
                  <input type="text" name="text" value=""/>
                  <input type="submit" value="Classify"</input>
                </form>
                TXT
        end

        @sinatra_thread = Thread.new do; puts "Starting Sinatra Server...";Sinatra::Application.run!; end
        Thread.pass
      end

      def self.init
        sinatra_server = SinatraServer.new nil
        # sinatra_server.sinatra_thread.join
      end
    end
  
  end

  if __FILE__ == $0
    SearchDaemon.init true
  end
end