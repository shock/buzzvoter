class PollsController < ApplicationController
  
  before_filter :require_user, :except=>[:show, :vote]
  SAMPLE_ANSWERS = [
    {:name=>"Johan Santana", :abbr=>"Santana"},
    {:name=>"Brandon Webb", :abbr=>"Webb"},
    {:name=>"C.C. Sabathia", :abbr=>"Sabathia"},
    {:name=>"Roy Halladay", :abbr=>"Halladay"},
    {:name=>"Tim Lincecum", :abbr=>"Lincecum"}
  ]
  SAMPLE_NAME = "Best MLB Pitcher"
  SAMPLE_QUESTION = "Who is the best pitcher in Major League Baseball today?"
  SAMPLE_POLL_TAG = "#MLBP"
  SAMPLE_REPLY_MESSAGE = "Your vote for #ANSWER# in the #POLLNAME# poll was registered."
  
  
  # GET /polls
  # GET /polls.xml
  def index
    @polls = Poll.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @polls }
    end
  end

  # GET /polls/1
  # GET /polls/1.xml
  def show
    @poll = Poll.find_by_id_or_url(params[:id])
    @votes = []
    @answers = @poll.get_answers_with_votes

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @poll }
    end
  end

  # GET /polls/1
  # GET /polls/1.xml
  def vote
    @poll = Poll.find_by_id_or_url(params[:id])
    @answers = @poll.answers_hash.values

    respond_to do |format|
      format.html # vote.html.erb
      format.xml  { render :xml => @poll }
    end
  end

  # GET /polls/new
  # GET /polls/new.xml
  def new
    @poll = Poll.new
    @poll.ending_time = Time.zone.now + 2.hours
    @poll.name = SAMPLE_NAME
    @poll.question = SAMPLE_QUESTION
    @poll.poll_tag = SAMPLE_POLL_TAG
    @poll.url = Poll.create_unique_url
    @poll.results_reply = true
    @poll.reply_message = SAMPLE_REPLY_MESSAGE
    @answers = SAMPLE_ANSWERS
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @poll }
    end
  end

  # GET /polls/1/edit
  def edit
    @poll = Poll.find_by_id_or_url(params[:id])
    @answers = @poll.answers_hash.values
  end

  # POST /polls
  # POST /polls.xml
  def create
    params[:poll][:user_id] = current_user.id
    @poll = Poll.new_from_form_fields(params[:poll])

    respond_to do |format|
      if @poll.errors.count == 0 && @poll.save
        flash[:notice] = 'Poll was successfully created.'
        format.html { redirect_to(@poll) }
        format.xml  { render :xml => @poll, :status => :created, :location => @poll }
      else
        if @poll.answers 
          @answers = @poll.answers_hash.values
        else
          @answers = SAMPLE_ANSWERS
        end
        format.html { render :action => "new" }
        format.xml  { render :xml => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /polls/1
  # PUT /polls/1.xml
  def update
    @poll = Poll.find_by_id_or_url(params[:id])

    respond_to do |format|
      if @poll.update_from_form_fields(params[:poll])
        flash[:notice] = 'Poll was successfully updated.'
        format.html { redirect_to(@poll) }
        format.xml  { head :ok }
      else
        @answers = @poll.answers.values
        format.html { render :action => "edit" }
        format.xml  { render :xml => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /polls/1
  # DELETE /polls/1.xml
  def destroy
    @poll = Poll.find_by_id_or_url(params[:id])
    @poll.destroy

    respond_to do |format|
      format.html { redirect_to(polls_url) }
      format.xml  { head :ok }
    end
  end
end
