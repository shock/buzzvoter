class Mailer < ActionMailer::Base
  add_template_helper (ApplicationHelper)
  # add_template_helper (TopicPostsHelper)
  
  private
  
  ##########################################################################
  # AuthLogic dups from ApplicationController, should D.R.Y. these up...
  #
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end
  #
  ###########################################################################
  
  public
  
  
  def exception_notification exception, message="", user="unrecorded"
    self.template_root = RAILS_ROOT+"/app/views/"  # unfortunately, this is necessary to get Mailer working outside of rails

    recipients      $APP_CONFIG[:admin][:email_recipients]
    from            $APP_CONFIG[:admin][:email_sender]
    subject         "EXCEPTION: #{exception.inspect}"
    body            :message=>message, :exception=>exception, :user=>user
    content_type    "text/html"
  end
  
  def system_alert system_alert
    self.template_root = RAILS_ROOT+"/app/views/"  # unfortunately, this is necessary to get Mailer working outside of rails

    recipients      $APP_CONFIG[:admin][:email_recipients]
    from            $APP_CONFIG[:admin][:email_sender]
    subject         "BuzzManager ALERT: Level #{system_alert.severity_level}"
    body            :system_alert=>system_alert
    content_type    "text/html"
  end
  
end
