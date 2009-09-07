class Vote < ActiveRecord::Base
  skip_time_zone_conversion_for_attributes << :tweet_created_at
  
end
