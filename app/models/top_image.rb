# Used for denormalized searches on (normal, vetted, visible, published) images.
class TopImage < ActiveRecord::Base

  IMAGE_LIMIT = 500 # Limit on how many images to index per TaxonConcept.

  self.primary_keys = :hierarchy_entry_id, :data_object_id
  belongs_to :hierarchy_entry
  belongs_to :data_object

  def self.rebuild
    TopImage::Rebuilder.rebuild
  end
end
