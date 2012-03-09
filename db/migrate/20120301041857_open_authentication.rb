class OpenAuthentication < ActiveRecord::Migration
  def self.up
    create_table :open_authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :guid
      t.string :token
      t.string :secret
      
      t.timestamps
    end
  end

  def self.down
    drop_table :open_authentications
  end
end