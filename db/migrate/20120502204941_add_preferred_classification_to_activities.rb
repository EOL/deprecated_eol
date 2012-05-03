class AddPreferredClassificationToActivities < EOL::LoggingMigration
  def self.up
    Activity.find_or_create('preferred_classification')
    ChangeableObjectType.find_or_create_by_ch_object_type('curated_taxon_concept_preferred_entry')
  end

  def self.down
    # Nothing to do.
  end
end
