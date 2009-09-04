class HomeController < ApplicationController
  before_filter :require_user, :only=>[]
  def index
    @recent_polls = Poll.recent
  end
end
