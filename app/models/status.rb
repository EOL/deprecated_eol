class Status < SpeciesSchemaModel
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events
  
  def self.inserted
    cached_find(:label, 'inserted', :serialize => true)
  end

  def self.updated
    cached_find(:label, 'updated', :serialize => true)
  end

  def self.unchanged
    cached_find(:label, 'unchanged', :serialize => true)
  end

end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: statuses
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: statuses
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

