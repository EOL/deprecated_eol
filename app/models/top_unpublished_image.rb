# Used for denormalized searches on (unpublished) images (ie: for curators).
class TopUnpublishedImage < ActiveRecord::Base
  self.primary_keys = :hierarchy_entry_id, :data_object_id
  belongs_to :hierarchy_entry
  belongs_to :data_object
end
