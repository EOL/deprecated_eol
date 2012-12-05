# This is only here to help specs load things to the right database.  Ignore it.
class DataObjectsInfoItem < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :info_item
  self.primary_keys = :data_object_id, :info_item_id
end
