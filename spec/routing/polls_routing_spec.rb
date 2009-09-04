require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PollsController do
  describe "route generation" do
    it "maps #index" do
      route_for(:controller => "polls", :action => "index").should == "/polls"
    end

    it "maps #new" do
      route_for(:controller => "polls", :action => "new").should == "/polls/new"
    end

    it "maps #show" do
      route_for(:controller => "polls", :action => "show", :id => "1").should == "/polls/1"
    end

    it "maps #edit" do
      route_for(:controller => "polls", :action => "edit", :id => "1").should == "/polls/1/edit"
    end

    it "maps #create" do
      route_for(:controller => "polls", :action => "create").should == {:path => "/polls", :method => :post}
    end

    it "maps #update" do
      route_for(:controller => "polls", :action => "update", :id => "1").should == {:path =>"/polls/1", :method => :put}
    end

    it "maps #destroy" do
      route_for(:controller => "polls", :action => "destroy", :id => "1").should == {:path =>"/polls/1", :method => :delete}
    end
  end

  describe "route recognition" do
    it "generates params for #index" do
      params_from(:get, "/polls").should == {:controller => "polls", :action => "index"}
    end

    it "generates params for #new" do
      params_from(:get, "/polls/new").should == {:controller => "polls", :action => "new"}
    end

    it "generates params for #create" do
      params_from(:post, "/polls").should == {:controller => "polls", :action => "create"}
    end

    it "generates params for #show" do
      params_from(:get, "/polls/1").should == {:controller => "polls", :action => "show", :id => "1"}
    end

    it "generates params for #edit" do
      params_from(:get, "/polls/1/edit").should == {:controller => "polls", :action => "edit", :id => "1"}
    end

    it "generates params for #update" do
      params_from(:put, "/polls/1").should == {:controller => "polls", :action => "update", :id => "1"}
    end

    it "generates params for #destroy" do
      params_from(:delete, "/polls/1").should == {:controller => "polls", :action => "destroy", :id => "1"}
    end
  end
end
