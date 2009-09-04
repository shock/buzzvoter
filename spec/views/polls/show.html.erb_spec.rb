require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/polls/show.html.erb" do
  include PollsHelper
  before(:each) do
    assigns[:poll] = @poll = stub_model(Poll,
      :name => "value for name",
      :url => "value for url",
      :question => "value for question",
      :answers => "value for answers",
      :results_reply => false,
      :reply_message => "value for reply_message",
      :owner => 
    )
  end

  it "renders attributes in <p>" do
    render
    response.should have_text(/value\ for\ name/)
    response.should have_text(/value\ for\ url/)
    response.should have_text(/value\ for\ question/)
    response.should have_text(/value\ for\ answers/)
    response.should have_text(/false/)
    response.should have_text(/value\ for\ reply_message/)
    response.should have_text(//)
  end
end
