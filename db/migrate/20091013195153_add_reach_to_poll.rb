class AddReachToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :reach, :integer, :default=>0
    Poll.update_all(:reach=>0)
  end

  def self.down
    remove_column :polls, :reach
  end
end
