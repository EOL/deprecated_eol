class DataObjectsHierarchyEntry < ActiveRecord::Base

  include EOL::CuratableAssociation

  self.primary_keys = :data_object_id, :hierarchy_entry_id

  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  scope :visible, -> { where(visibility_id: Visibility.get_visible.id) }
  scope :invisible, -> { where(visibility_id: Visibility.get_invisible.id) }

  def self.find_all(values)
    DataObjectsHierarchyEntry.where(
      values.map do |pair|
        "(#{DataObjectsHierarchyEntry.primary_keys.first} = #{pair.first} AND " +
        "#{DataObjectsHierarchyEntry.primary_keys.second} = #{pair.second})"
      end.join(' OR ')
    )
  end

  def taxon_concept
    hierarchy_entry.taxon_concept
  end

  def guid
    data_object.guid
  end

end
