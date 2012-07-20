class Status < ActiveRecord::Base
  uses_translations
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events
  
  def self.inserted
    cached_find_translated(:label, 'inserted', 'en')
  end

  def self.updated
    cached_find_translated(:label, 'updated', 'en')
  end

  def self.unchanged
    cached_find_translated(:label, 'unchanged', 'en')
  end

  def self.download_pending
    cached_find_translated(:label, 'Download Pending', 'en')
  end

  def self.download_in_progress
    cached_find_translated(:label, 'Download In Progress', 'en')
  end

  def self.download_succeeded
    cached_find_translated(:label, 'Download Succeeded', 'en')
  end

  def self.download_failed
    cached_find_translated(:label, 'Download Failed', 'en')
  end

end
