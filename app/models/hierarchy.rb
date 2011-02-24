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
class Hierarchy < SpeciesSchemaModel

  belongs_to :agent           # This is the attribution.
  has_and_belongs_to_many :collection_types

  named_scope :browsable, :conditions => {:browsable => 1}

  has_many :hierarchy_entries
  alias entries hierarchy_entries
  
  def self.browsable_by_label
    cached('browsable_by_label') do
      Hierarchy.browsable.sort_by {|h| h.form_label }
    end
  end
  
  def self.taxonomy_providers
    cached('taxonomy_providers') do
      ['Integrated Taxonomic Information System (ITIS)', 'CU*STAR Classification', 'NCBI Taxonomy', 'Index Fungorum', $DEFAULT_HIERARCHY_NAME].collect{|label| Hierarchy.find_by_label(label, :order => "hierarchy_group_version desc")}
    end
  end

  def self.default
    cached_find(:label, $DEFAULT_HIERARCHY_NAME, :serialize => true)
  end

  # This is the first hierarchy we used, and we need it to serve "old" URLs (ie: /taxa/16222828 => Roenbergensis)
  def self.original
    cached_find(:label, "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007", :serialize => true)
  end

  def self.eol_contributors
    cached_find(:label, "Encyclopedia of Life Contributors", :serialize => true)
  end

  def self.ncbi
    cached('ncbi', :serialize => true) do
      Hierarchy.find_by_label("NCBI Taxonomy", :order => "hierarchy_group_version desc")
    end
  end
  
  def self.browsable_for_concept(taxon_concept)
    Hierarchy.find_by_sql("SELECT h.* FROM hierarchies h JOIN hierarchy_entries he ON (h.id = he.hierarchy_id) WHERE h.browsable = 1 AND he.taxon_concept_id=#{taxon_concept.id}")
  end
  
  def form_label
    return descriptive_label unless descriptive_label.blank?
    return label
  end
  
  def attribution
    string = [agent]
    string.first.full_name = string.first.display_name = label # To change the name from just "Catalogue of Life"
    return string
  end
  
  def kingdoms(params = {})
    add_include = []
    add_select = {}
    if params[:include_stats]
      add_include << :hierarchy_entry_stat
      add_select[:hierarchy_entry_stats] = '*'
    end
    if params[:include_common_names]
      add_include << {:taxon_concept => {:preferred_common_names => :name}}
      add_select[:taxon_concept_names] = :language_id
    end
    
    vis = [Visibility.visible.id, Visibility.preview.id]
    k = HierarchyEntry.core_relationships(:add_include => add_include, :add_select => add_select).find_all_by_hierarchy_id_and_parent_id_and_visibility_id(id, 0, vis)
    HierarchyEntry.sort_by_name(k)
  end
end
