# Collection of general and useful Ruby class extensions

class DateTime
  LOG_TIME_FORMAT = "%a %Y-%m-%d %H:%M:%S"
  
  # Format date and time for log timestamp
  def ltf
    strftime(LOG_TIME_FORMAT)
  end
end

class Time
  LOG_TIME_FORMAT = "%a %Y-%m-%d %H:%M:%S"
  
  # Format date and time for log timestamp
  def ltf
    strftime(LOG_TIME_FORMAT)
  end
end

class ActiveSupport::TimeWithZone
  LOG_TIME_FORMAT = "%a %Y-%m-%d %H:%M:%S"
  
  # Format date and time for log timestamp
  def ltf
    strftime(LOG_TIME_FORMAT)
  end
end

module MinMaxComparison
  def max( value )
    if value > self
      value
    else
      self
    end
  end
  
  def min( value )
    if value < self
      value
    else
      self
    end
  end
end

class Fixnum
  include MinMaxComparison
end

class Rational
  include MinMaxComparison
end

class Float
  include MinMaxComparison
end