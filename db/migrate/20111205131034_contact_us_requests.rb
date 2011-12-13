class ContactUsRequests < ActiveRecord::Migration
  def self.up
    create_table :contact_us_requests do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :comment
      t.integer :topic_area_id
    end
  end

  def self.down
    drop_table :contact_us_requests
  end
end
