class CreatePermissions < ActiveRecord::Migration
  def change

    create_table :permissions do |t|
      t.integer :users_count :default => 0, :null => false
      t.timestamps
    end
    add_index :permissions, :name, :unique => true

    create_table :translated_permissions do |t|
      t.string :name, :length => 64, :null => false, :unique => true
      t.integer :language_id, :null => false
      t.integer :permission_id, :null => false
    end
    add_index :translated_permissions, [:permission_id, :language_id], :unique => true

    create_table :permissions_users do |t|
      t.integer :user_id, :null => false
      t.integer :permission_id, :null => false
      t.timestamps
    end
    add_index :permissions_users, [:permission_id, :user_id], :unique => true

  end
end
