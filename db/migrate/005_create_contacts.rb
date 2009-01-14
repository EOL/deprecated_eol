class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.integer :contact_subject_id
      t.string :name, :email
      t.text :comments
      t.string :ip_address
      t.string :referred_page
      t.string :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :contacts
  end
end
