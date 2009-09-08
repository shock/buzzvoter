class AddProcessedToPolls < ActiveRecord::Migration
  def self.up
    add_column :polls, :processed, :boolean, :default=>false
    Poll.update_all(:processed=>false)
  end

  def self.down
    remove_column :polls, :processed
  end
end
