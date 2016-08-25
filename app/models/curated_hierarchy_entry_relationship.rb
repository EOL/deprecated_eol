# Used during harvesting (only).
class CuratedHierarchyEntryRelationship < ActiveRecord::Base
  self.primary_keys = "hierarchy_entry_id_1", "hierarchy_entry_id_2"

  belongs_to :from_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_1"
  belongs_to :to_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_2"

  scope :equivalent, -> { where(equivalent: true) }
  scope :not_equivalent, -> { where(equivalent: false) }

  # NOTE: this is not fast; takes about 10 seconds or so.
  def self.exclusions
    exclusions = {}
    CuratedHierarchyEntryRelationship.not_equivalent.
      includes(:from_hierarchy_entry, :to_hierarchy_entry).
      # Some of the entries have gone missing! Skip those:
      select { |ce| ce.from_hierarchy_entry && ce.to_hierarchy_entry }.
      each do |cher|
      from_entry = cher.from_hierarchy_entry.id
      from_tc = cher.from_hierarchy_entry.taxon_concept_id
      to_entry = cher.to_hierarchy_entry.id
      to_tc = cher.to_hierarchy_entry.taxon_concept_id
      exclusions[from_entry] ||= []
      exclusions[from_entry] << to_tc
      exclusions[to_entry] ||= []
      exclusions[to_entry] << from_tc
    end
    exclusions
  end

end
