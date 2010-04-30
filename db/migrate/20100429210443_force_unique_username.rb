class ForceUniqueUsername < ActiveRecord::Migration
  def self.up
    execute('alter table users add unique index unique_username (username);') 
  end

  def self.down
    execute('alter table users drop index unique_username;') 
  end
end
