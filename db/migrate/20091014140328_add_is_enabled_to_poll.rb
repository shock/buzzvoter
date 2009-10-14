class AddIsEnabledToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :is_enabled, :boolean, :default=>false
    Poll.update_all(:is_enabled=>true)
  end

  def self.down
    remove_column :polls, :is_enabled
  end
end
