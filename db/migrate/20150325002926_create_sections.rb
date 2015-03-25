class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections, id: nil do |t|
      t.integer :article_id, null: false
      t.integer :toc_item_id, null: false
    end
    add_index :sections, [:article_id, :toc_item_id], name: "pk"
    add_index :sections, :article_id
  end
end
