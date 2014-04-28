# a denormalized table containing all the objects a concept
# should show in its RSS feed
# TODO - remove this. It's used by harvesting, so don't delete the table, but the Rails code doesn't need to reference it or know about it.
class DataObjectsTaxonConcept < ActiveRecord::Base
  self.primary_keys = :taxon_concept_id, :data_object_id
  belongs_to :taxon_concept
  belongs_to :data_object
  belongs_to :data_type
end
