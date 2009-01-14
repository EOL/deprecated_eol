class AddTaxonConceptIdToDataObjectLog < ActiveRecord::Migration
  def self.database_model
    return "LoggingModel"
  end

  def self.up
    add_column :data_object_logs, :taxon_concept_id, :integer
  end

  def self.down
    remove_column :data_object_logs, :taxon_concept_id
  end
end
