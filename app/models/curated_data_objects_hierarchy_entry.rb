class CuratedDataObjectsHierarchyEntry < ActiveRecord::Base

  include EOL::CuratableAssociation

  belongs_to :user
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  belongs_to :data_objects_hierarchy_entry, :class_name => 'DataObjectsHierarchyEntry',
    :foreign_key => [:data_object_id, :hierarchy_entry_id]

  def replicate
    if user.is_curator? || user.is_admin?
      if user.assistant_curator? # Assistant curators get to have it auto-unreviewed:
        self.vetted_id = Vetted.unknown.id
      else # ...other curators and admins get to have it auto-trusted:
        self.vetted_id = Vetted.trusted.id
      end
    else
      # ...and other users have it automatically unknown:
      self.vetted_id = Vetted.unknown.id
    end
    self.visibility_id = Visibility.visible.id # should be visible if a new revision is created by anyone.
    self.save
    self
  end

end
