class AddLayoutToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :bg_color, :string, :default=>'FFFFFF'
    add_column :polls, :text_color, :string, :default=>'222222'
    add_column :polls, :link_color, :string, :default=>'0000CC'
    add_column :polls, :tile_bg_image, :boolean, :default=>false
    add_column :polls, :logo_height, :integer, :default=>0
    Poll.update_all({:bg_color=>'FFFFFF', :text_color=>'222222', :link_color=>'0000CC', :tile_bg_image=>false, :logo_height=>0})
  end

  def self.down
    remove_column :polls, :logo_height
    remove_column :polls, :tile_bg_image
    remove_column :polls, :link_color
    remove_column :polls, :text_color
    remove_column :polls, :bg_color
  end
end
