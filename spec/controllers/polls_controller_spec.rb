require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PollsController do

  def mock_poll(stubs={})
    @mock_poll ||= mock_model(Poll, stubs)
  end

  describe "GET index" do
    it "assigns all polls as @polls" do
      Poll.stub!(:find).with(:all).and_return([mock_poll])
      get :index
      assigns[:polls].should == [mock_poll]
    end
  end

  describe "GET show" do
    it "assigns the requested poll as @poll" do
      Poll.stub!(:find).with("37").and_return(mock_poll)
      get :show, :id => "37"
      assigns[:poll].should equal(mock_poll)
    end
  end

  describe "GET new" do
    it "assigns a new poll as @poll" do
      Poll.stub!(:new).and_return(mock_poll)
      get :new
      assigns[:poll].should equal(mock_poll)
    end
  end

  describe "GET edit" do
    it "assigns the requested poll as @poll" do
      Poll.stub!(:find).with("37").and_return(mock_poll)
      get :edit, :id => "37"
      assigns[:poll].should equal(mock_poll)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created poll as @poll" do
        Poll.stub!(:new).with({'these' => 'params'}).and_return(mock_poll(:save => true))
        post :create, :poll => {:these => 'params'}
        assigns[:poll].should equal(mock_poll)
      end

      it "redirects to the created poll" do
        Poll.stub!(:new).and_return(mock_poll(:save => true))
        post :create, :poll => {}
        response.should redirect_to(poll_url(mock_poll))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved poll as @poll" do
        Poll.stub!(:new).with({'these' => 'params'}).and_return(mock_poll(:save => false))
        post :create, :poll => {:these => 'params'}
        assigns[:poll].should equal(mock_poll)
      end

      it "re-renders the 'new' template" do
        Poll.stub!(:new).and_return(mock_poll(:save => false))
        post :create, :poll => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested poll" do
        Poll.should_receive(:find).with("37").and_return(mock_poll)
        mock_poll.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :poll => {:these => 'params'}
      end

      it "assigns the requested poll as @poll" do
        Poll.stub!(:find).and_return(mock_poll(:update_attributes => true))
        put :update, :id => "1"
        assigns[:poll].should equal(mock_poll)
      end

      it "redirects to the poll" do
        Poll.stub!(:find).and_return(mock_poll(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(poll_url(mock_poll))
      end
    end

    describe "with invalid params" do
      it "updates the requested poll" do
        Poll.should_receive(:find).with("37").and_return(mock_poll)
        mock_poll.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :poll => {:these => 'params'}
      end

      it "assigns the poll as @poll" do
        Poll.stub!(:find).and_return(mock_poll(:update_attributes => false))
        put :update, :id => "1"
        assigns[:poll].should equal(mock_poll)
      end

      it "re-renders the 'edit' template" do
        Poll.stub!(:find).and_return(mock_poll(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested poll" do
      Poll.should_receive(:find).with("37").and_return(mock_poll)
      mock_poll.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the polls list" do
      Poll.stub!(:find).and_return(mock_poll(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(polls_url)
    end
  end

end
