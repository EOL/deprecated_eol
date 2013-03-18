class CreateUserAddedData < ActiveRecord::Migration
  def change
    create_table :user_added_data do |t|
      t.integer :user_id, :null => false
      t.string :subject
      t.string :predicate
      t.string :object
      t.timestamps
      t.datetime :deleted_at
    end
    add_index :user_added_data, :user_id, :name => 'user_id'
    add_index :user_added_data, :subject, :name => 'subject'

    create_table :user_added_data_metadata do |t|
      t.integer :user_added_data_id, :null => false
      t.string :predicate
      t.string :object
      t.timestamps
    end
    add_index :user_added_data_metadata, :user_added_data_id, :name => 'user_added_data_id'

    create_table :curated_structured_data do |t|
      t.integer :user_id, :null => false
      t.string :subject
      t.string :predicate
      t.string :object
      t.integer :vetted_id, :null => false
      t.integer :visibility_id, :null => false
      t.integer :comment_id, :null => false
      t.timestamps
    end
    add_index :curated_structured_data, :user_id, :name => 'user_id'
    add_index :curated_structured_data, :subject, :name => 'subject'
  end
end
