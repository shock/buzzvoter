require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Poll do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :url => "value for url",
      :question => "value for question",
      :answers => "value for answers",
      :ending_time => Time.now,
      :results_reply => false,
      :reply_message => "value for reply_message",
      :owner => 
    }
  end

  it "should create a new instance given valid attributes" do
    Poll.create!(@valid_attributes)
  end
end
