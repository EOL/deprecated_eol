class CreateTaxonConceptExemplarArticles < ActiveRecord::Migration
  def self.up
    create_table(:taxon_concept_exemplar_articles, :primary_key => 'taxon_concept_id') do |t|
      t.integer :data_object_id
    end
  end

  def self.down
    drop_table :taxon_concept_exemplar_articles
  end
end