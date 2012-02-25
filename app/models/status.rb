class Status < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events
  
  def self.inserted
    cached_find_translated(:label, 'inserted')
  end

  def self.updated
    cached_find_translated(:label, 'updated')
  end

  def self.unchanged
    cached_find_translated(:label, 'unchanged')
  end

end
