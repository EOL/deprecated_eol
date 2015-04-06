class CreateContentCurations < ActiveRecord::Migration
  def change
    # We will rename this when we have a chance, but for now:
    create_table :content_curations do |t|
      t.integer :content_id, null: false
      t.integer :user_id, null: false
      t.string :attribute, null: false
      t.string :was
      t.string :now
    end
    add_index :content_curations, :content_id
    # So a user can know what they have curated:
    add_index :content_curations, :user_id
  end
end
