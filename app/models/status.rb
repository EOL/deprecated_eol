class Status < ActiveRecord::Base
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

  def self.download_pending
    cached_find_translated(:label, 'Download Pending')
  end

  def self.download_in_progress
    cached_find_translated(:label, 'Download In Progress')
  end

  def self.download_succeeded
    cached_find_translated(:label, 'Download Succeeded')
  end

  def self.download_failed
    cached_find_translated(:label, 'Download Failed')
  end

end
