module PollsHelper
  def poll_status poll
    if poll.active?
      "#{distance_of_time_in_words_to_now poll.ending_time} left"
    else
      "Closed"
    end
  end
end
