class DataObjectsHierarchyEntry < ActiveRecord::Base

  include EOL::CuratableAssociation

  self.primary_keys = :data_object_id, :hierarchy_entry_id

  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  def taxon_concept
    hierarchy_entry.taxon_concept
  end

  def guid
    data_object.guid
  end

end
