class DataObjectsHarvestEvent < SpeciesSchemaModel
  set_primary_keys :data_object_id, :harvest_event_id
  
  belongs_to :harvest_event
  belongs_to :data_object
  belongs_to :status  
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_objects_harvest_events
#
#  data_object_id   :integer(4)      not null
#  harvest_event_id :integer(4)      not null
#  status_id        :integer(1)      not null
#  guid             :string(32)      not null

