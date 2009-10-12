class AddImagesToPoll < ActiveRecord::Migration
  def self.up
    add_column :polls, :bg_image_file_name,    :string
    add_column :polls, :bg_image_content_type, :string
    add_column :polls, :bg_image_file_size,    :integer
    add_column :polls, :bg_image_updated_at,   :datetime
    add_column :polls, :use_bg_image, :boolean

    add_column :polls, :logo_file_name,    :string
    add_column :polls, :logo_content_type, :string
    add_column :polls, :logo_file_size,    :integer
    add_column :polls, :logo_updated_at,   :datetime
    add_column :polls, :use_logo, :boolean

  end

  def self.down
    remove_column :polls, :bg_image_file_name
    remove_column :polls, :bg_image_content_type
    remove_column :polls, :bg_image_file_size
    remove_column :polls, :bg_image_updated_at
    remove_column :polls, :use_bg_image

    remove_column :polls, :logo_file_name
    remove_column :polls, :logo_content_type
    remove_column :polls, :logo_file_size
    remove_column :polls, :logo_updated_at
    remove_column :polls, :use_logo
  end
end
