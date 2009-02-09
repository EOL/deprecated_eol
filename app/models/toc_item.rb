class TocItem < SpeciesSchemaModel
  
  set_table_name 'table_of_contents'
  acts_as_tree :order => 'view_order'
  
  attr_writer :has_content
  attr_writer :has_unpublished_content
  
  has_many :info_items, :foreign_key => :toc_id
  
  has_and_belongs_to_many :data_objects, :join_table => 'data_objects_table_of_contents', :foreign_key => 'toc_id'

  def self.bhl
    @@bhl ||= TocItem.find_by_label('Biodiversity Heritage Library')
  end
  
  def self.specialist_projects
    @@specialist_projects ||= TocItem.find_by_label('Specialist Projects')
  end
  
  def self.common_names
    @@common_names ||= TocItem.find_by_label('Common Names')
  end
  
  def self.overview
    @@search_the_web ||= TocItem.find_by_label('Overview')
  end
  
  def self.search_the_web
    @@search_the_web ||= TocItem.find_by_label('Search the Web')
  end
  
  def has_content?
    @has_content
  end

  def has_unpublished_content?
    @has_unpublished_content == true
  end

  def is_child?
    !(self.parent_id.nil? or self.parent_id == 0) 
  end

  # TODO - make a version of this for Hierarchy Entry:
  # TODO - MEDIUM PRIO - refactor this to take a taxon directly, rather than the id.
  def self.toc_for(taxon_id, options = {})
    
    toc = DataObject.for_taxon(TaxonConcept.find(taxon_id), :text, options)
    # Find out which toc items have unpublished content. Method published is accessible here  because
    # toc items are found by sql which has data_object fields. Every toc item corresponds to one data object
    # and is repeated potentially more than one time. They become unique after sort
    toc = toc.map {|item| item.has_unpublished_content = true if item.published.to_i  == 0; item}
    # Add specialist projects if there are entries in the mappings table for this name:
    if Mapping.count_by_sql([
      'SELECT 1 from mappings map, taxon_concept_names tcn WHERE map.name_id = tcn.name_id AND tcn.taxon_concept_id = ? LIMIT 1',
      taxon_id]) > 0
        toc << TocItem.specialist_projects
    end

    # BHL: 
    # from concepts to page_names, using name_id, LIMIT 1 ...if they are there, add BHL node.
    if PageName.count_by_sql([
      'SELECT 1 FROM taxon_concept_names tcn JOIN page_names pn USING (name_id) WHERE tcn.taxon_concept_id = ? LIMIT 1',
      taxon_id]) > 0
        toc << TocItem.bhl
    end

    # Common Names:
    if TaxonConcept.count_by_sql([
      'SELECT 1 from taxon_concept_names tcn WHERE taxon_concept_id = ? and vern = 1 LIMIT 1',
      taxon_id]) > 0
        toc << TocItem.common_names
    end
    # from taxon_concepts to taxon_concept_names to name_languages.  Make sure the language_id != scientific_name, taxonomic_unit,
    # unknown, etc... we'll make a class method to grab these. LIMIT 1 ...if one is there, add common names node.

    # Catalog of Life:
    # Perhaps this should just be synonyms, and it will grab all (unique) synonyms from all hierarchies. TODO
    vetted_only = (options[:user].blank? ? false : options[:user].vetted)
    toc << TocItem.search_the_web unless vetted_only
  
    # TODO - make a Toc class that inherits from array and use that instead of these class methods:
    return TocItem.sort_toc(TocItem.add_empty_parents(toc))

  end
  #
  # Okay, ruby-sorting was a NIGHTMARE (but possible), so to make it slightly more maintainable (but probably slower):
  # First, find all of the parents:
  def self.sort_toc(toc)
    parents = toc.select { |item| item.parent_id == 0 }.uniq.sort_by{ |item| item.view_order }
    new_toc = []
    # Now append the parent, then all its sorted children
    parents.each do |parent|
      new_toc << parent
      new_toc += toc.select { |item| item.parent_id == parent.id }.uniq.sort_by { |item| item.view_order }
    end
    return new_toc
  end

  # We go through the TOC to find those elements that are children.  We do this in two passes, beacuse modifying an array *while*
  # looping through it is the path of the darkside.
  def self.add_empty_parents(toc)
    children = []
    pp toc
    toc.each_with_index do |item, index|
      item.has_content = true
      if item.is_child?
        children << [index, item.parent_id]
      end
    end
    # So here we loop through those elements and add empty parents to the TOC:
    children.each do |child|
      toc[child[0], 0] = TocItem.find(child[1]) unless
        toc.any? {|i| i.id == child[1]} # This says, "unless the parent is already in the TOC"
    end
    return toc
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: table_of_contents
#
#  id         :integer(2)      not null, primary key
#  parent_id  :integer(2)      not null
#  label      :string(255)     not null
#  view_order :integer(1)      not null

