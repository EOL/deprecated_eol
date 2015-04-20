class ResourceContribution < ActiveRecord::Base
  belongs_to :resource
  belongs_to :data_point_uri
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :taxon_concept
  attr_accessible :source, :resource_id, :data_point_uri_id, :data_object_id, :hierarchy_entry_id, :taxon_concept_id, :identifier, :type
end
