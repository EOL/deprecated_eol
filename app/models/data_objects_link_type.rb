class DataObjectsLinkType < ActiveRecord::Base
  self.primary_key = 'data_object_id'
  belongs_to :data_object
  belongs_to :link_type
end
