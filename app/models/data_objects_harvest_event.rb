class DataObjectsHarvestEvent < ActiveRecord::Base
  self.primary_keys = :data_object_id, :harvest_event_id
  
  belongs_to :harvest_event
  belongs_to :data_object
  belongs_to :status  
end
