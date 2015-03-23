class CreateSummaries < ActiveRecord::Migration
  def change
    create_table :summaries do |t|
      t.integer :taxon_concept_id
      t.string :scientific_name
      t.integer :data_object_id
      t.string :thumbnail_cache_id
      t.timestamps
    end
    add_index :summaries, :taxon_concept_id, unique: true
  end
end
