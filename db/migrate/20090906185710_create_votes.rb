class CreateVotes < ActiveRecord::Migration
  def self.up
    create_table :votes do |t|
      t.integer :poll_id
      t.string :answer_abbr
      t.integer :tweet_id, :limit=>8
      t.integer :voter_id, :limit=>8
      t.string :voter_name
      t.string :text
      t.integer :to_user_id, :limit=>8
      t.string :profile_image_url
      t.datetime :tweet_created_at
      t.boolean :is_valid

      t.timestamps
    end
  end

  def self.down
    drop_table :votes
  end
end
