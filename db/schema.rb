# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091012035209) do

  create_table "polls", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "question"
    t.text     "answers"
    t.datetime "ending_time"
    t.boolean  "results_reply"
    t.string   "reply_message"
    t.integer  "user_id"
    t.integer  "vote_count",            :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "poll_tag"
    t.datetime "last_updated"
    t.integer  "total_results"
    t.integer  "new_results"
    t.datetime "last_started"
    t.string   "status",                :default => "none"
    t.integer  "seconds_to_execute"
    t.string   "vote_tweet"
    t.boolean  "processed",             :default => false
    t.string   "bg_color",              :default => "FFFFFF"
    t.string   "text_color",            :default => "222222"
    t.string   "link_color",            :default => "0000CC"
    t.boolean  "tile_bg_image",         :default => false
    t.integer  "logo_height",           :default => 0
    t.string   "bg_image_file_name"
    t.string   "bg_image_content_type"
    t.integer  "bg_image_file_size"
    t.datetime "bg_image_updated_at"
    t.boolean  "use_bg_image",          :default => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean  "use_logo",              :default => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                              :null => false
    t.string   "twitter_id",                         :null => false
    t.string   "crypted_password",                   :null => false
    t.string   "password_salt",                      :null => false
    t.string   "persistence_token",                  :null => false
    t.string   "single_access_token",                :null => false
    t.string   "perishable_token",                   :null => false
    t.string   "time_zone",                          :null => false
    t.integer  "login_count",         :default => 0, :null => false
    t.integer  "failed_login_count",  :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "votes", :force => true do |t|
    t.integer  "poll_id"
    t.string   "answer_abbr"
    t.integer  "tweet_id",          :limit => 8
    t.integer  "voter_id",          :limit => 8
    t.string   "voter_name"
    t.string   "text"
    t.integer  "to_user_id",        :limit => 8
    t.string   "profile_image_url"
    t.datetime "tweet_created_at"
    t.boolean  "is_valid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
