require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/polls/index.html.erb" do
  include PollsHelper

  before(:each) do
    assigns[:polls] = [
      stub_model(Poll,
        :name => "value for name",
        :url => "value for url",
        :question => "value for question",
        :answers => "value for answers",
        :results_reply => false,
        :reply_message => "value for reply_message",
        :owner => 
      ),
      stub_model(Poll,
        :name => "value for name",
        :url => "value for url",
        :question => "value for question",
        :answers => "value for answers",
        :results_reply => false,
        :reply_message => "value for reply_message",
        :owner => 
      )
    ]
  end

  it "renders a list of polls" do
    render
    response.should have_tag("tr>td", "value for name".to_s, 2)
    response.should have_tag("tr>td", "value for url".to_s, 2)
    response.should have_tag("tr>td", "value for question".to_s, 2)
    response.should have_tag("tr>td", "value for answers".to_s, 2)
    response.should have_tag("tr>td", false.to_s, 2)
    response.should have_tag("tr>td", "value for reply_message".to_s, 2)
    response.should have_tag("tr>td", .to_s, 2)
  end
end
