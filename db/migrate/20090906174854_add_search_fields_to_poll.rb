class AddSearchFieldsToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :poll_tag, :string
    add_column :polls, :last_updated, :datetime
    add_column :polls, :total_results, :integer
    add_column :polls, :new_results, :integer
    add_column :polls, :last_started, :datetime
    add_column :polls, :status, :string, :default=>'none'
    add_column :polls, :seconds_to_execute, :integer
  end

  def self.down
    remove_column :polls, :poll_tag
    remove_column :polls, :seconds_to_execute
    remove_column :polls, :status
    remove_column :polls, :last_started
    remove_column :polls, :new_results
    remove_column :polls, :total_results
    remove_column :polls, :last_updated
  end
end
