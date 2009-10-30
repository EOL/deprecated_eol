class AddRememberTokenForUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :remember_token, :string, :limit => 255
    add_column :users, :remember_token_expires_at, :timestamp
  end

  def self.down
    remove_column :users, :remember_token
    remove_column :users, :remember_token_expires_at
  end
end
