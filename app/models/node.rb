# This is a class used by Tramea.
#
# NOTE: this does NOT act as a tree (acts_as_tree); just use the hierarchy entry
# for that. No use in duplicating that information here, we rarely need it (yet)...
class Node < ActiveRecord::Base
  belongs_to :hierarchy_entry, foreign_key: "id"
  belongs_to :parent, class: "HierarchyEntry"
  belongs_to :taxon_concept
  belongs_to :source

  has_many :children, class: "Node", foreign_key: "parent_id"
  #TODO: ancestors...
  has_many :contents,
      primary_key: "id",
      foreign_key: "hierarchy_entry_id"

  # NOTE: this will NOT create the contents. It's assumed that's done via the
  # taxon concept / page.
  def self.from_hierarchy_entry(entry)
    return find(entry.id) if
      exists?(id: entry.id)
    source = Source.from_resource(entry.resource)
    node = create({
      id: entry.id,
      taxon_concept_id: entry.taxon_concept_id,
      source_id: source.id,
      exemplar: TaxonConceptPreferredEntry.exists?(
        hierarchy_entry_id: entry.id,
        taxon_concept_id: entry.taxon_concept_id
      ),
      species_or_sub: entry.species_or_below?,
      scientific_name: entry.name.string,
      rank: entry.rank.label.downcase
    })
    # TODO: store ancestors. Children are covered.
    node
  end
end
