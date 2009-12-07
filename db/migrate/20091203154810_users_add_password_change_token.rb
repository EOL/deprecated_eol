class UsersAddPasswordChangeToken < ActiveRecord::Migration
  def self.up
    execute 'alter table users add column password_reset_token char(40)'
    execute 'alter table users add column password_reset_token_expires_at datetime'
    add_index :users, :password_reset_token, :name => 'index_users_on_password_reset_token', :unique => true
  end

  def self.down
    change_table :users do |t|
      t.remove :password_reset_token
      t.remove :password_reset_token_expires_at
    end
  end
end
