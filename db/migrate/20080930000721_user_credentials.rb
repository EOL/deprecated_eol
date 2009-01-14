class UserCredentials < ActiveRecord::Migration
  
  def self.up
    add_column(:users, :credentials, :text, :default => '', :null => false)
  end

  def self.down
    remove_column(:users, :credentials)
  end

end
