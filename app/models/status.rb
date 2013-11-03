class Status < ActiveRecord::Base

  uses_translations
  has_many :harvest_events_hierarchy_entries
  has_many :data_objects_harvest_events

  include NamedDefaults
  set_defaults :label, %w{Inserted Updated Unchanged}
  
end
