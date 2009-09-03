# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_buzzvoter_session',
  :secret      => 'bfb27be6b82a88c91d90c01bd4d8afbc5148947e3ebbfd5aad448575ad7ac52965e823d9ed6a079a9653532c0f5e236bf74c55fb4802d4c6372716fb1d49ab81'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
