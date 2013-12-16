class CreateTaxonSummary < ActiveRecord::Migration

  def change
    create_table (:taxon_summaries) do |t|
      t.string :classification_summary, length: 600
      t.string :default_common_name, length: 300
      t.string :scientific_name, length: 300
      t.integer :taxon_concept_id, :unique => true
      t.integer :entry_id
      t.integer :rank_id
      t.integer :image_id
    end
    add_index :taxon_summaries, :taxon_concept_id, unique: true
    add_index :taxon_summaries, :image_id # Because, when cutators affect the image, we want to look it up by this association.
  end

end
