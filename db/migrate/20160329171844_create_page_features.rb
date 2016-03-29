class CreatePageFeatures < ActiveRecord::Migration
  def change
    create_table :page_features do |t|
      t.integer :taxon_concept_id, null: false
      t.boolean :map_json, default: false
      t.timestamps
    end
    add_index :page_features, :taxon_concept_id
  end
end
