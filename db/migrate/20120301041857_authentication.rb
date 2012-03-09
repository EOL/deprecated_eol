class Authentication < ActiveRecord::Migration
  def self.up
    create_table :authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :guid
      t.string :user_name
      t.string :given_name
      t.string :family_name
      t.string :full_name
      t.string :email
      t.string :token
      t.string :secret
      
      t.timestamps
    end
  end

  def self.down
    drop_table :authentications
  end
end