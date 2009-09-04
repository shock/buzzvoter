require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/polls/edit.html.erb" do
  include PollsHelper

  before(:each) do
    assigns[:poll] = @poll = stub_model(Poll,
      :new_record? => false,
      :name => "value for name",
      :url => "value for url",
      :question => "value for question",
      :answers => "value for answers",
      :results_reply => false,
      :reply_message => "value for reply_message",
      :owner => 
    )
  end

  it "renders the edit poll form" do
    render

    response.should have_tag("form[action=#{poll_path(@poll)}][method=post]") do
      with_tag('input#poll_name[name=?]', "poll[name]")
      with_tag('input#poll_url[name=?]', "poll[url]")
      with_tag('input#poll_question[name=?]', "poll[question]")
      with_tag('textarea#poll_answers[name=?]', "poll[answers]")
      with_tag('input#poll_results_reply[name=?]', "poll[results_reply]")
      with_tag('input#poll_reply_message[name=?]', "poll[reply_message]")
      with_tag('input#poll_owner[name=?]', "poll[owner]")
    end
  end
end
