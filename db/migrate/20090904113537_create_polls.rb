class CreatePolls < ActiveRecord::Migration
  def self.up
    create_table :polls do |t|
      t.string :name
      t.string :url
      t.string :question
      t.text :answers
      t.datetime :ending_time
      t.boolean :results_reply
      t.string :reply_message
      t.integer :user_id
      t.boolean :closed
      t.integer :vote_count, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :polls
  end
end
