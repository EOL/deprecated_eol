class CreateTaxonDataExemplars < ActiveRecord::Migration
  def change
    create_table :taxon_data_exemplars do |t|
      t.integer :taxon_concept_id
      t.integer :parent_id
      t.string :parent_type, :limit => 64
    end
    add_index :taxon_data_exemplars, :taxon_concept_id
  end
end
