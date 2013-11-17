class Status < ActiveRecord::Base

  uses_translations
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events

  include Enumerated
  enumerated :label, %w(inserted updated unchanged)
  
end
