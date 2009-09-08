class AddSuggestedVoteTweetToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :vote_tweet, :string
  end

  def self.down
    remove_column :polls, :vote_tweet
  end
end
