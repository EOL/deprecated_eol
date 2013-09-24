require 'eol/curatable_association'
class CuratedDataObjectsHierarchyEntry < ActiveRecord::Base

  include EOL::CuratableAssociation

  belongs_to :user
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  belongs_to :data_objects_hierarchy_entry, :class_name => 'DataObjectsHierarchyEntry',
    :foreign_key => [:data_object_id, :hierarchy_entry_id]

  def replicate(new_vetted_id)
    self.vetted_id = new_vetted_id
    self.visibility_id = Visibility.visible.id
    self.save
    self
  end

  def taxon_concept
    hierarchy_entry.taxon_concept
  end

  def guid
    data_object_guid
  end

end
