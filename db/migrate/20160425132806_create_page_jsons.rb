class CreatePageJsons < ActiveRecord::Migration
  def change
    create_table :page_jsons do |t|
      t.integer :page_id, null: false
      t.text :ld, null: false
      t.text :context
      t.timestamps
    end
    add_index(:page_jsons, :page_id, unique: true)
    # Allow us to re-generate old pages (e.g.: ("updated_at < ?", 1.month.ago)):
    add_index(:page_jsons, :updated_at)
  end
end
