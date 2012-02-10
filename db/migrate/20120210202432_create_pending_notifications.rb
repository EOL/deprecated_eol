class CreatePendingNotifications < ActiveRecord::Migration
  def self.up
    create_table :pending_notifications do |t|
      t.references :user
      t.references :notification_frequency
      t.integer :target_id
      t.string :target_type, :limit => 64
      t.string :reason, :limit => 64
      t.datetime :sent_at
      t.timestamps
    end
    add_index :pending_notifications, :user_id
    add_index :pending_notifications, :sent_at
  end

  def self.down
    drop_table :pending_notifications
  end
end
