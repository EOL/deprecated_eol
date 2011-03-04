class Status < SpeciesSchemaModel
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events
  
  def self.inserted
    cached_find(:label, 'inserted')
  end

  def self.updated
    cached_find(:label, 'updated')
  end

  def self.unchanged
    cached_find(:label, 'unchanged')
  end

end
