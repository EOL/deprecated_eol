# Represents a version of the Tree of Life
#
# Because the tree changes as new species are discovered and other species are
# reclassified, etc, there's a Hierarchy object available for each version
# of the Tree of Life that's been imported, eg.
#
#   >> Hierarchy.all.map &:label
#   => [
#        "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007",
#        "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008"
#      ]
#
require 'invert'

class Hierarchy < ActiveRecord::Base
  belongs_to :agent           # This is the attribution.
  has_and_belongs_to_many :collection_types
  has_one :resource
  has_one :dwc_resource, class_name: Resource.to_s, foreign_key: :dwc_hierarchy_id
  has_many :hierarchy_entries
  has_many :kingdoms, class_name: HierarchyEntry.to_s, foreign_key: [ :hierarchy_id ], primary_key: [ :id ],
    conditions: Proc.new { "`hierarchy_entries`.`visibility_id` IN (#{Visibility.get_visible.id}, #{Visibility.get_preview.id}) AND `hierarchy_entries`.`parent_id` = 0" }
  has_many :hierarchy_reindexings
  has_many :synonyms, through: :hierarchy_entries

  validates_presence_of :label
  validates_length_of :label, maximum: 255

  before_save :reset_request_publish, if: Proc.new { |hierarchy| hierarchy.browsable == 1 }

  scope :browsable, conditions: { browsable: 1 }

  alias entries hierarchy_entries

  def self.sort_by_user_or_agent_name(hierarchies)
    hierarchies.sort_by do |h|
      [ h.request_publish ? 0 : 1,
        h.browsable.to_i * -1,
        h.user_or_agent_or_label_name ]
    end
  end

  def self.browsable_by_label
    cached('browsable_by_label') do
      Hierarchy.browsable.sort_by {|h| h.form_label }
    end
  end

  def self.taxonomy_providers
    cached('taxonomy_providers') do
      ['Integrated Taxonomic Information System (ITIS)', 'CU*STAR Classification', 'NCBI Taxonomy', 'Index Fungorum', $DEFAULT_HIERARCHY_NAME].collect{|label| Hierarchy.find_by_label(label, order: "hierarchy_group_version desc")}
    end
  end

  def self.default
    cached_find(:label, $DEFAULT_HIERARCHY_NAME)
  end

  def self.col
    @@col ||= cached('col') do
      Hierarchy.where("label LIKE 'Species 2000 & ITIS Catalogue of Life%%'").includes(:agent).last
    end
  end

  def self.gbif
    @@gbif ||= cached_find(:label, 'GBIF Nub Taxonomy')
  end

  # This is the first hierarchy we used, and we need it to serve "old" URLs (ie: /taxa/16222828 => Roenbergensis)
  def self.original
    cached_find(:label, "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007")
  end

  def self.eol_contributors
    Agent # ARRRRRRGH... Dumbest error; can't use the include in tests w/o this.
    @@eol_contributors ||= cached('eol_contributors') do
      Hierarchy.find_by_label("Encyclopedia of Life Contributors", include: :agent)
    end
  end

  def self.iucn_structured_data
    @iucn_structured_data ||= Resource.iucn_structured_data.hierarchy
  end

  def self.ubio
    cached_find(:label, "uBio Namebank")
  end

  def self.ncbi
    @@ncbi ||= cached('ncbi') do
      Hierarchy.find_by_label("NCBI Taxonomy", order: "hierarchy_group_version desc")
    end
  end

  def self.worms
    @@worms ||= cached('worms') do
      Hierarchy.find_by_label("WORMS Species Information (Marine Species)")
    end
  end

  def self.itis
    @@itis ||= cached('itis') do
      Hierarchy.find_by_label('Integrated Taxonomic Information System (ITIS)', order: 'id desc')
    end
  end

  def self.wikipedia
    @@wikipedia ||= cached('wikipedia') do
      Hierarchy.find_by_label('Wikipedia', order: 'id desc')
    end
  end

  def self.browsable_for_concept(taxon_concept)
    Hierarchy.joins(:hierarchy_entries).select('hierarchies.id, hierarchies.label, hierarchies.descriptive_label').
      where(['hierarchies.browsable = 1 AND hierarchy_entries.taxon_concept_id = ?', taxon_concept.id])
  end

  def self.available_via_api
    available_hierarchies = Hierarchy.browsable
    available_hierarchies << Hierarchy.gbif if Hierarchy.gbif
    available_hierarchies.sort_by(&:id)
  end

  def sort_order
    return 1 if self == Hierarchy.col
    return 2 if self == Hierarchy.itis
    return 3 if self.label == 'Avibase - IOC World Bird Names (2011)'
    return 4 if self.label == 'WORMS Species Information (Marine Species)'
    return 5 if self.label == 'FishBase (Fish Species)'
    return 6 if self.label == 'IUCN Red List (Species Assessed for Global Conservation)'
    return 7 if self.label == 'Index Fungorum'
    return 8 if self.label == 'Paleobiology Database'
    9999
  end

  def flatten
    Hierarchy::Flattener.flatten(self)
  end

  def form_label
    return descriptive_label unless descriptive_label.blank?
    return label
  end

  def content_partner
    # the resource has a content partner
    if resource && resource.content_partner
      resource.content_partner
    # there is an archive resource, which has a content_partner
    elsif dwc_resource && dwc_resource.content_partner
      dwc_resource.content_partner
    # the hierarchy has no resource, but it has an agent which has a user which has content partners
    elsif agent.user && !agent.user.content_partners.blank?
      agent.user.content_partners.first
    end
  end

  def merge_matching_concepts
    Hierarchy::ConceptMerger.merges_for_hierarchy(self)
  end

  # Returns (a potentially VERY large) array of ids that were previously
  # published.
  def unpublish
    ids = unpublish_and_hide_hierarchy_entries
    unpublish_synonyms
    ids
  end

  def request_to_publish_can_be_made?
    !self.browsable? && !request_publish
  end

  def user_or_agent
    if resource && resource.content_partner && resource.content_partner.user
      resource.content_partner.user
    elsif agent
      agent
    else
      nil
    end
  end

  def user_or_agent_or_label_name
    if user_or_agent
      user_or_agent.full_name
    else
      label
    end
  end

  def display_title
    if resource
      resource.title
    elsif dwc_resource
      dwc_resource.title
    else
      user_or_agent_or_label_name
    end
  end

  def repopulate_flattened
    kingdoms.each(&:repopulate_flattened_hierarchy)
  end

  def reindex
    HierarchyReindexing.enqueue(self) if hierarchy_reindexings.pending.blank?
  end

private

  def reset_request_publish
    self.request_publish = false
    return true
  end

  def unpublish_and_hide_hierarchy_entries
    entry_ids = hierarchy_entries.where(published: true).pluck(:id)
    hierarchy_entries.where(id: entry_ids).
      update_all(published: false, visibility_id: Visibility.get_invisible.id)
    entry_ids
  end

  def unpublish_synonyms
    synonyms.where(synonyms: { published: true }).
      update_all(["synonyms.published = ?", false])
  end

end
