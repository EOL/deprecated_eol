class CreateTaxonConceptExemplarImage < ActiveRecord::Migration
  def self.up
    execute("CREATE TABLE `taxon_concept_exemplar_images` (
      `taxon_concept_id` int(10) unsigned NOT NULL,
      PRIMARY KEY (`taxon_concept_id`),
      `data_object_id` int(10) unsigned
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
  end

  def self.down
    drop_table :taxon_concept_exemplar_images
  end
end
