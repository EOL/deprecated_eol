class CuratedDataObjectsHierarchyEntry < ActiveRecord::Base

  include EOL::CuratableAssociation

  belongs_to :user
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  belongs_to :data_objects_hierarchy_entry, :class_name => 'DataObjectsHierarchyEntry',
    :foreign_key => [:data_object_id, :hierarchy_entry_id]

  def replicate(new_dato)
    CuratedDataObjectsHierarchyEntry.create(:hierarchy_entry_id => hierarchy_entry_id,
                                            :data_object_id => new_dato.id, :user_id => user_id,
                                            :vetted_id => vetted_id,
                                            :visibility_id => visibility_id)
  end

end
