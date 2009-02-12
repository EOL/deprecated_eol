# Represents an entry in the Tree of Life (see Hierarchy)
#
# #hierarchy is the 'version' of the Tree of Life (every year a new list of all species comes out)
# #rank is ... ?
# #name is ... ?
#
# TODO - ADD COMMENTS
class HierarchyEntry < SpeciesSchemaModel

  acts_as_tree :order => 'lft'

  belongs_to :hierarchy 
  belongs_to :rank 
  belongs_to :name
  belongs_to :taxon_concept

  has_many :concepts
  has_many :top_images, :foreign_key => :hierarchy_entry_id
  has_many :curators, :class_name => 'User', :foreign_key => :curator_hierarchy_entry_id

  has_many :agents, :finder_sql => 'SELECT * FROM agents JOIN agents_hierarchy_entries ahe ON (agents.id = ahe.agent_id)
                                      WHERE ahe.hierarchy_entry_id = #{id} ORDER BY ahe.view_order'

  has_one :hierarchies_content

  def name(detail_level = :middle, language = Language.english, context = nil)
    return raw_name(detail_level, language, context).firstcap
  end

  def canonical_form
    return name_object.canonical_form
  end

  def raw_name(detail_level = :middle, language = Language.english, context = nil)
    return '?' if self[:name_id].nil?
    case detail_level.to_sym
    when :italicized_canonical
      return name_object.italicized_canonical
    when :canonical
      return name_object.canonical
    when :natural_form
      return name_object.string
    when :expert
      if context == :classification and not HierarchyEntry.leaf_node_ranks.include? self[:rank_id]
        return name_object.string
      else
        # TODO - there are cases here where we need to pay attention to language.
        italics = name_object.italicized
        return italics.blank? ?
            "<i>#{name_object.string.firstcap}</i>" :
            italics
      end
    else # :middle  (though we don't want to rely on that)
      language ||= Language.english # Not sure why; this didn't work as a default to the argument.
      common_name = TaxonConceptName.find_by_taxon_concept_id_and_language_id_and_vern_and_preferred(taxon_concept_id, language.id, 1, 1)
      common_name ||= TaxonConceptName.find_by_taxon_concept_id_and_language_id_and_vern(taxon_concept_id, language.id, 1)
      return common_name if context == :object # This allows people to get the name and its language.
      if common_name.nil?
        if context == :classification
          return raw_name(:expert, language, :classification)
        else
          return raw_name(:italicized_canonical)
        end
      end
      return common_name.name.string
    end
  end

  def toc
    TocItem.toc_for(id)
  end

  def media
    {:images => hierarchies_content.image != 0 || hierarchies_content.child_image  != 0,
     :video  => hierarchies_content.flash != 0 || hierarchies_content.youtube != 0,
     :map    => hierarchies_content.gbif_image != 0}
  end

  # This is a complete port of content_level_sub() from functions.php:
  def content_level
    if is_leaf_node?
      return 4 if hierarchies_content.content_level == 4
      return 3 unless hierarchies_content.text == 0
      return 1
    else
      return 0 if hierarchies_content.nil?
      return hierarchies_content.content_level == 0 ? 1 : hierarchies_content.content_level
    end
  end

  def rank_label
    
    rank.nil? ? "taxon" : rank.label
    
  end
  
  def iucn
    # So, this used to add "dato.data_type_id = #{DaataType.find_by_label('Text')}".  But an intial version of the DB had IUCN types as
    # images. I removed it, thinking that it doesn't really matter in the case of IUCN stuff... it'll only ever be one object, so we
    # don't much care.
    my_iucn = DataObject.find_by_sql([<<EOIUCNSQL, id, Agent.iucn.id])

    SELECT dato.*
      FROM resources r, agents_resources ar, data_objects dato, concepts c, taxa t, data_objects_taxa dot
      WHERE
        dot.data_object_id = dato.id AND
        dot.taxon_id = t.id AND
        t.resource_id = r.id AND
        c.name_id = t.name_id AND
        c.hierarchy_entry_id = ? AND
        ar.resource_id = r.id AND
        ar.agent_id = ?
      LIMIT 1 # iucn

EOIUCNSQL
    return my_iucn.blank? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/', :description => 'NOT EVALUATED') : my_iucn
  end
  
  def approved_curators
    he_all = TaxonConcept.direct_ancestors(taxon_concept)
    ids = he_all.collect do |he| he.id end
    all = User.find(:all, :conditions => ["curator_hierarchy_entry_id IN (#{ids.join(',')}) and curator_approved IS TRUE"])
    return all
  end

  def with_parents
    HierarchyEntry.with_parents self
  end
  alias hierarchy_entries_with_parents with_parents

  def is_curatable_by? user
    hierarchy_entries_with_parents_above_clade = TaxonConcept.direct_ancestors(taxon_concept)
    permitted = hierarchy_entries_with_parents_above_clade.find {|entry| user.curator_hierarchy_entry_id == entry.id }
    if permitted then true else false end
  end

  # this is meant to be filtered by a taxon concept so it will find all hierarchy entries AND their ancestors/parents for a given TaxonConcept
  def self.with_parents taxon_concept_or_hierarchy_entry = nil
    if taxon_concept_or_hierarchy_entry.is_a?TaxonConcept
      HierarchyEntry.find_all_by_taxon_concept_id(taxon_concept_or_hierarchy_entry.id).inject([]) do |all, he|
        all << he
        all += he.ancestors
        all
      end
    elsif taxon_concept_or_hierarchy_entry.is_a?HierarchyEntry
      [taxon_concept_or_hierarchy_entry] + taxon_concept_or_hierarchy_entry.ancestors
    else
      raise "Don't know how to return with_parents for #{ taxon_concept_or_hierarchy_entry.inspect }"
    end
  end

  def self.species_rank
    335
  end

  def self.infraspecies_rank
    175
  end

  def self.leaf_node_ranks
    [HierarchyEntry.species_rank, HierarchyEntry.infraspecies_rank]
  end

  def is_leaf_node?
    return HierarchyEntry.leaf_node_ranks.include?(rank_id)
  end

  # Singleton.  top_images, from which this is based, rarely changes.
  def images()
    @images ||= DataObject.images_for_hierarchy_entry(id)
  end

  # Singleton.  Videos also rarely change.
  def videos
    @videos ||= DataObject.videos_for_hierarchy_entry(id)
  end

  def map
    @map ||= DataObject.map_for_hierarchy_entry(id)
  end

  def valid
    return false if hierarchies_content.nil? # This really only happens in test environ, but...
    hierarchies_content.content_level >= $VALID_CONTENT_LEVEL
  end

  def enable
    return false if hierarchies_content.nil?
    return is_leaf_node? ? (hierarchies_content.text == 1 or hierarchies_content.image == 1) : valid
  end

  def ancestors
    return @ancestors unless @ancestors.nil?
    @ancestors = [self]
    @ancestors.unshift(find_default_hierarchy_ancestor) unless self.hierarchy_id == Hierarchy.default.id
    if @ancestors.first.nil?
      @ancestors = [self]
      return @ancestors
    end
    until @ancestors.first.parent.nil? do
      @ancestors.unshift(@ancestors.first.parent) 
    end 
    return @ancestors
  end
  
  def ancestors_hash(detail_level = :middle, language = Language.english)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.
    
    if self.hierarchy_id != Hierarchy.default.id
      entry_in_common = find_default_hierarchy_ancestor
      return entry_in_common.ancestors_hash(detail_level, language)
    end
    
    ancestors_ids = ancestors.map {|a| a.id}
    nodes = SpeciesSchemaModel.connection.execute("SELECT n1.string scientific_name, n1.italicized scientific_name_italicized, n2.string common_name, n2.italicized common_name_italicized, he.taxon_concept_id id, he.id hierarchy_entry_id, he.lft lft, he.rgt rgt, he.rank_id, hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image, r.label rank_string FROM hierarchy_entries he JOIN names n1 ON (he.name_id=n1.id) JOIN hierarchies_content hc ON (he.id=hc.hierarchy_entry_id) LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)) ON (he.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id}) LEFT JOIN ranks r ON (he.rank_id=r.id) WHERE he.id in (#{ancestors_ids.join(",")}) ORDER BY he.lft ASC").all_hashes
    
    nodes.map do |node| 
      node_to_hash(node, detail_level)
    end
  end
  
  def children_hash(detail_level = :middle, language = Language.english)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.
        
    children = SpeciesSchemaModel.connection.execute("SELECT n1.string scientific_name, n1.italicized scientific_name_italicized, n2.string common_name, n2.italicized common_name_italicized, he.taxon_concept_id id, he.id hierarchy_entry_id, he.lft lft, he.rgt rgt, he.rank_id, hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image, r.label rank_string FROM hierarchy_entries he JOIN names n1 ON (he.name_id=n1.id) JOIN hierarchies_content hc ON (he.id=hc.hierarchy_entry_id) LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)) ON (he.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id}) LEFT JOIN ranks r ON (he.rank_id=r.id) WHERE he.parent_id=#{id} GROUP BY he.taxon_concept_id").all_hashes
    
    children.map do |node|
      node_to_hash(node, detail_level)
    end
  end

  def kingdom
    return ancestors.first rescue nil
  end

  def smart_thumb
    return images.blank? ? nil : images.first.smart_thumb
  end

  def smart_medium_thumb
    return images.blank? ? nil : images.first.smart_medium_thumb
  end

  def smart_image
    return images.blank? ? nil : images.first.smart_image
  end
  
  def self.node_xml(entry_node)
    node  = "\t\t<node>\n";
    node += "\t\t\t<taxonID>#{entry_node[:hierarchy_entry_id]}</taxonID>\n";
    node += "\t\t\t<nameString>#{CGI::escapeHTML entry_node[:name]}</nameString>\n";
    node += "\t\t\t<rankName>#{CGI::escapeHTML entry_node[:rank_string]}</rankName>\n";
    node += "\t\t\t<valid>#{entry_node[:valid]}</valid>\n";
    node += "\t\t\t<enable>#{entry_node[:enable]}</enable>\n";
    node += "\t\t</node>\n";
  end

  def classification(options = {})

    current_user = options[:current_user] || User.create_new
    
    ancestor_hash = ancestors_hash(current_user.expertise, current_user.language)
    child_hash = children_hash(current_user.expertise, current_user.language).sort { |a,b|
                       a[:name] <=> b[:name] }
    
    xml  = "<results>\n"
    xml += "\t<ancestry>\n"
    xml += ancestor_hash[0..-2].collect {|a| HierarchyEntry.node_xml(a)}.join
    xml += "\t</ancestry>\n"
    
    xml += "\t<current>\n";
    xml += ancestor_hash[-1..-1].collect {|a| HierarchyEntry.node_xml(a)}.join
    xml += "\t</current>\n";
    
    xml += "\t<children>\n"
    xml += child_hash.collect {|a| HierarchyEntry.node_xml(a)}.join
    xml += "\t</children>\n"
    
    xml += "\t<kingdoms>\n"
    xml += Hierarchy.default.kingdoms_hash(current_user.expertise, current_user.language).collect {|a| HierarchyEntry.node_xml(a)}.join
    xml += "\t</kingdoms>\n"
    
    # siblings = HierarchyEntry.find_all_by_parent_id_and_hierarchy_id(self.parent_id, self.hierarchy_id, :include => :name)
    # siblings.delete_if {|sib| sib.id == self.id } # We don't want the current entry in this list!
    # siblings = siblings.sort_by {|entry| entry.name(current_user.expertise, current_user.language) }
    # xml += xml_for_group(siblings, 'siblings', current_user) unless siblings.empty?
    # 
    # xml += "\t<attribution>\n";
    # xml += classification_attribution.collect {|ca| ca.node_xml}.join
    # xml += "\t</attribution>\n";
    xml += "</results>\n";

  end

  def classification_attribution(params={})
    attribution=hierarchy.label
    attribution = [hierarchy.agent]
    attribution.first.full_name = attribution.first.display_name = hierarchy.label # To change the name from just "Catalogue of Life"
    attribution += agents
  end

private
  # Because we hijack the built-in name method...
  def name_object
    return Name.find(self[:name_id]) # Because we override the name() method.
  end

  def xml_for_group(group, name, current_user)
    xml = ''
    unless group.empty?
      xml += "\t<#{name}>\n";
      group.each do |entry|
        xml += entry.node_xml(current_user)
      end
      xml += "\t</#{name}>\n";
    end
    return xml
  end

  def find_default_hierarchy_ancestor
    he = self
    until he.taxon_concept.in_hierarchy(Hierarchy.default.id)
      return nil if he.parent_id == 0
      he = he.parent
    end
    he.taxon_concept.entry    
  end
  
  def node_to_hash(node, detail_level)
    is_leaf_node = (node['rgt'].to_i - node['lft'].to_i == 1)
    name = (detail_level.to_sym == :expert) ? node['scientific_name'].firstcap : (node['common_name'] == nil  ? node['scientific_name'].firstcap : node['common_name'].firstcap)
    #name = node['scientific_name_italicized'] if (is_leaf_node && (detail_level.to_sym == :expert || node['common_name'] == nil))
    name = node['scientific_name_italicized'] if (Rank.italicized_ids.include?(node['rank_id'].to_i) && (detail_level.to_sym == :expert || node['common_name'] == nil))
    {
      :name => name,
      :italicized => detail_level.to_sym == :expert ? node['scientific_name_italicized'].firstcap : (node['common_name_italicized'] == nil  ? node['scientific_name_italicized'].firstcap : node['common_name_italicized'].firstcap),
      :id => node['id'],
      :rank_string => node['rank_string'],
      :hierarchy_entry_id => node['hierarchy_entry_id'],
      :valid => node['content_level'].to_i >= $VALID_CONTENT_LEVEL.to_i,
      :enable => is_leaf_node ? (node['text'].to_i == 1 || node['image'].to_i == 1) : (node['text'].to_i == 1 || node['image'].to_i == 1 || node['child_image'].to_i == 1)
    }
  end
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: hierarchy_entries
#
#  id               :integer(4)      not null, primary key
#  hierarchy_id     :integer(2)      not null
#  name_id          :integer(4)      not null
#  parent_id        :integer(4)      not null
#  rank_id          :integer(2)      not null
#  remote_id        :string(255)     not null
#  taxon_concept_id :integer(4)      not null
#  ancestry         :string(500)     not null
#  depth            :integer(1)      not null
#  identifier       :string(20)      not null
#  lft              :integer(4)      not null
#  rgt              :integer(4)      not null

