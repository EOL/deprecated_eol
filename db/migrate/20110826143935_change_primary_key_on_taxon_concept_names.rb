class ChangePrimaryKeyOnTaxonConceptNames < ActiveRecord::Migration
  def self.up
    TaxonConceptName.connection.execute('ALTER TABLE taxon_concept_names DROP PRIMARY KEY')
    TaxonConceptName.connection.execute('ALTER TABLE taxon_concept_names ADD PRIMARY KEY(`taxon_concept_id`, `name_id`, `source_hierarchy_entry_id`, `language_id`, `synonym_id`)')
  end

  def self.down
    TaxonConceptName.connection.execute('ALTER TABLE taxon_concept_names DROP PRIMARY KEY')
    TaxonConceptName.connection.execute('ALTER TABLE taxon_concept_names ADD PRIMARY KEY(`taxon_concept_id`, `name_id`, `source_hierarchy_entry_id`, `language_id`)')
  end
end
