# This is only here to help specs load things to the right database.  Ignore it.
class DataObjectsTableOfContent < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :toc_item, foreign_key: :toc_id
  self.primary_keys = :data_object_id, :toc_id
end
