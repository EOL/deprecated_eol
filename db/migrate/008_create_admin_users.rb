class CreateAdminUsers < ActiveRecord::Migration
  
  def self.up
    create_table :admin_users do |t|
      t.string :password_salt, :password_hash, :null=>false
      t.string :email, :default=>'',:null=>false 
      t.string :fullname, :default=>'',:null=>false 
      t.boolean :active, :default=>true, :null=>false                          
      t.timestamps
    end

  end

  def self.down
    drop_table :admin_users
  end
end
