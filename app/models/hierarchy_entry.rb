# Represents an entry in the Tree of Life (see Hierarchy).  This is one of the major models of the EOL codebase, and most
# data links to these instances.
class HierarchyEntry < SpeciesSchemaModel

  acts_as_tree :order => 'lft'

  belongs_to :hierarchy 
  belongs_to :name
  belongs_to :rank 
  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility
  belongs_to :name_object, :class_name => "Name", :foreign_key => :name_id

  has_many :agents_hierarchy_entries
  has_many :agents, :finder_sql => 'SELECT * FROM agents JOIN agents_hierarchy_entries ahe ON (agents.id = ahe.agent_id)
                                      WHERE ahe.hierarchy_entry_id = #{id} ORDER BY ahe.view_order'
  has_many :concepts
  has_many :top_images, :foreign_key => :hierarchy_entry_id
  has_many :synonyms

  has_one :hierarchies_content
  has_one :hierarchy_entry_stat

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

  def self.node_xml(entry_node)
    node  = "\t\t<node>\n";
    node += "\t\t\t<taxonID>#{entry_node[:hierarchy_entry_id]}</taxonID>\n";
    node += "\t\t\t<nameString>#{CGI::escapeHTML entry_node[:name]}</nameString>\n";
    node += "\t\t\t<rankName>#{CGI::escapeHTML entry_node[:rank_string]}</rankName>\n";
    node += "\t\t\t<valid>#{entry_node[:valid]}</valid>\n";
    node += "\t\t\t<enable>#{entry_node[:enable]}</enable>\n";
    node += "\t\t</node>\n";
  end

  def self.children_details(hierarchy_entry_id, params = {})
    result = SpeciesSchemaModel.connection.execute("
    SELECT he.id, he.identifier, he.lft, he.rgt, he.rank_id, he.parent_id, he.hierarchy_id, he.taxon_concept_id, n.string name_string, n.italicized italicized_name, r.label rank_label, hc.content_level
      FROM hierarchy_entries he
      JOIN names n ON (he.name_id = n.id)
      LEFT JOIN ranks r ON (he.rank_id = r.id)
      LEFT JOIN hierarchies_content hc ON (he.id = hc.hierarchy_entry_id)
      WHERE he.parent_id = #{hierarchy_entry_id}
      AND he.published = 1
      AND he.visibility_id != #{Visibility.invisible.id}").all_hashes

    if params[:include_common_names]
      params[:common_name_language] ||= Language.english
      common_names = TaxonConcept.quick_common_names(result.collect{|r| r['taxon_concept_id']}, params[:common_name_language])
    end
    if params[:include_stats]
      found_stats = HierarchyEntryStat.find_all_by_hierarchy_entry_id(result.collect{|r| r['id']})
      all_stats = {}
      found_stats.each do |s|
        all_stats[s['hierarchy_entry_id'].to_i] = s
      end
    end
    result.each do |r|
      if Rank.italicized_ids.include?(r['rank_id'].to_i) && !r['italicized_name'].blank?
        r['name_string'] = r['italicized_name'].firstcap!
      else 
        r['name_string'] =  r['name_string'].firstcap!
      end
      r['descendants'] = r['rgt'].to_i - r['lft'].to_i - 1
      r['has_content'] = r['content_level'].to_i > 1
      r['name_string'] = common_names[r['taxon_concept_id'].to_i] unless common_names.blank? || common_names[r['taxon_concept_id'].to_i].blank?
      r['stats'] = all_stats[r['id'].to_i] unless all_stats[r['id'].to_i].blank?
    end
    result.sort!{|a,b| a['name_string'] <=> b['name_string']}
  end

  def get_ancestry(ancestry_array = [])
    ancestry_array.unshift self
    return ancestry_array unless parent_id.to_i > 0
    parent_hierarchy_entry = HierarchyEntry.find(parent_id, :select => 'id, parent_id, name_id, published, taxon_concept_id')
    parent_hierarchy_entry.get_ancestry(ancestry_array)
  end

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
      if context == :classification and not Rank.italicized_ids.include? self[:rank_id]
        return name_object.string
      else
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

  def media
    {:images => hierarchies_content.image != 0 || hierarchies_content.child_image  != 0,
     :video  => hierarchies_content.flash != 0 || hierarchies_content.youtube != 0,
     :map    => hierarchies_content.map != 0}
  end

  # This is a complete port of content_level_sub() from functions.php:
  def content_level
    if species_or_below?
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

  def with_parents
    HierarchyEntry.with_parents self
  end
  alias hierarchy_entries_with_parents with_parents

  # Returns true if the specified user has access to the TaxonConcept that this HierarchyEntry belongs to
  # (because curators have access to pages, not really specific HierarchyEntry instances.  This is confusing
  # because users have a HierarchyEntry that their 
  def is_curatable_by? user
    return taxon_concept.is_curatable_by?(user)
  end

  def species_or_below?
    return Rank.italicized_ids.include?(rank_id)
  end

  def images
    @images ||= DataObject.images_for_hierarchy_entry(id)
  end

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
    return species_or_below? ? (hierarchies_content.text == 1 or hierarchies_content.image == 1) : valid
  end

  def ancestors(cross_reference_hierarchy = nil)
    ancestors = [self]
    if cross_reference_hierarchy
      ancestors.unshift(find_ancestor_in_hierarchy(cross_reference_hierarchy)) unless self.hierarchy_id == cross_reference_hierarchy.id
      if ancestors.first.nil?
        ancestors = [self]
        return ancestors
      end
    end
    until ancestors.first.parent_id == 0 || ancestors.first.parent.nil? do
      ancestors.unshift(ancestors.first.parent)
    end
    return ancestors
  end

  def ancestors_hash(detail_level = :middle, language = Language.english, cross_reference_hierarchy = nil, secondary_hierarchy = nil)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.

    if cross_reference_hierarchy && secondary_hierarchy && taxon_concept.in_hierarchy?(secondary_hierarchy) && find_ancestor_in_hierarchy(cross_reference_hierarchy)
      return merged_ancestors_hash(detail_level, language, cross_reference_hierarchy, secondary_hierarchy)
    end

    if !cross_reference_hierarchy.nil? && self.hierarchy_id != cross_reference_hierarchy.id
      entry_in_common = find_ancestor_in_hierarchy(cross_reference_hierarchy)
      return {} if entry_in_common.nil?
      return entry_in_common.ancestors_hash(detail_level, language)
    end

    ancestors_ids = ancestors(cross_reference_hierarchy).map {|a| a.id}
    nodes = ancestors_hash_by_language_id_and_he_id(language.id, :ordered => true)
    deduped_nodes = []
    depth = 0
    nodes.each do |node|
      if !deduped_nodes[depth-1].nil? && node['id'] == deduped_nodes[depth-1]['id']
        deduped_nodes[depth-1] = node if !cross_reference_hierarchy.nil? && node['source_hierarchy_id'].to_i == cross_reference_hierarchy.id
      else
        deduped_nodes[depth] = node
        depth += 1
      end
    end

    deduped_nodes.map do |node| 
      node_to_hash(node, detail_level)
    end
  end

  def merged_ancestors_hash(detail_level, language, cross_reference_hierarchy, secondary_hierarchy)
    language ||= Language.english
    node = ancestors_hash_by_language_id_and_he_id(language.id)[0]
    ancestors = []
    ancestors << node_to_hash(node, detail_level)
    if node['parent_id'].to_i != 0
      parent_hierarchy_entry = HierarchyEntry.find(node['parent_id'].to_i)
      more_ancs = if entry_in_hierarchy = parent_hierarchy_entry.taxon_concept.entry_in_hierarchy(cross_reference_hierarchy)
        entry_in_hierarchy.ancestors_hash(detail_level, language, cross_reference_hierarchy)
      else
        parent_hierarchy_entry.merged_ancestors_hash(detail_level, language, cross_reference_hierarchy, secondary_hierarchy)
      end
      # The | operator performs set unity on arrays (essentially like adding and then uniq'ing):
      ancestors = more_ancs | ancestors
    end

    return ancestors
  end

  def children_hash(detail_level = :middle, language = Language.english, primary_hierarchy = nil, secondary_hierarchy = nil)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.

    if secondary_hierarchy
      #TODO - seriously?!?
      children = SpeciesSchemaModel.connection.execute("SELECT n1.string scientific_name, n1.italicized scientific_name_italicized, n2.string common_name, n2.italicized common_name_italicized, he_children.taxon_concept_id id, he_children.id hierarchy_entry_id, he_children.hierarchy_id, he_children.parent_id, he_children.lft lft, he_children.rgt rgt, he_children.rank_id, hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image, r.label rank_string FROM hierarchy_entries he_parents JOIN hierarchy_entries some_children ON (he_parents.id=some_children.parent_id) JOIN hierarchy_entries he_children ON (some_children.taxon_concept_id=he_children.taxon_concept_id) JOIN names n1 ON (he_children.name_id=n1.id) LEFT JOIN hierarchies_content hc ON (he_children.id=hc.hierarchy_entry_id) LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)) ON (he_children.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id}) LEFT JOIN ranks r ON (he_children.rank_id=r.id) WHERE he_parents.taxon_concept_id=#{taxon_concept_id} AND he_children.hierarchy_id IN (#{hierarchy_id}, #{secondary_hierarchy.id}) ORDER BY id").all_hashes

      deduped_children = []
      used_concepts_indices = []
      index = 0;
      children.each do |child|
        if !used_concepts_indices[child['id'].to_i].nil?
          if child['hierarchy_id'].to_i == primary_hierarchy.id
            deduped_children[used_concepts_indices[child['id'].to_i]] = child
          end
        else
          # child_concept = TaxonConcept.find(child['id'].to_i)
          # if entry_in_primary_hierarchy = child_concept.entry_in_hierarchy(primary_hierarchy)
          #   child = entry_in_primary_hierarchy.details_hash(language)
          # end
          if entry_in_primary_hierarchy = TaxonConcept.find_entry_in_hierarchy(child['id'].to_i, primary_hierarchy.id)
            next if entry_in_primary_hierarchy.parent_id != id
          end
          deduped_children[index] = child
          used_concepts_indices[child['id'].to_i] = index
          index += 1
        end
      end
      children = deduped_children

    else
      # TODO - again?!?
      children = SpeciesSchemaModel.connection.execute("SELECT n1.string scientific_name, n1.italicized scientific_name_italicized, n2.string common_name, n2.italicized common_name_italicized, he.taxon_concept_id id, he.id hierarchy_entry_id, he.hierarchy_id, he.lft lft, he.rgt rgt, he.rank_id, hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image, r.label rank_string FROM hierarchy_entries he JOIN names n1 ON (he.name_id=n1.id) LEFT JOIN hierarchies_content hc ON (he.id=hc.hierarchy_entry_id) LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)) ON (he.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id}) LEFT JOIN ranks r ON (he.rank_id=r.id) WHERE he.parent_id=#{id} GROUP BY he.taxon_concept_id").all_hashes
    end

    children.map do |node|
      node_to_hash(node, detail_level)
    end
  end

  def kingdom(hierarchy = nil)
    return ancestors(hierarchy).first rescue nil
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
    xml += hierarchy.kingdoms_hash(current_user.expertise, current_user.language).collect {|a| HierarchyEntry.node_xml(a)}.join
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
    attribution = []

    # its possible that the hierarchy is not associated with an agent
    if hierarchy.agent
      attribution = [hierarchy.agent]
      attribution.first.full_name = attribution.first.display_name = hierarchy.label # To change the name from just "Catalogue of Life"
    end
    attribution += agents
  end

  def agents_roles
    agents_roles = []

    # its possible that the hierarchy is not associated with an agent
    if h_agent = hierarchy.agent
      h_agent.full_name = h_agent.display_name = hierarchy.label # To change the name from just "Catalogue of Life"
      role = AgentRole.find_or_create_by_label('Source')
      agents_roles << AgentsHierarchyEntry.new(:hierarchy_entry => self, :agent => h_agent, :agent_role => role, :view_order => 0)
    end
    agents_roles += agents_hierarchy_entries
  end

  def has_gbif_identifier?
    return false unless hierarchies_content
    return false unless hierarchies_content.map
    return false if hierarchies_content.map == 0
    return false if identifier.blank?
    return true
  end

  # Walk up the list of ancestors until you find a node that we can map to the specified hierarchy.
  def find_ancestor_in_hierarchy(hierarchy)
    he = self
    until he.nil? || he.taxon_concept.nil? || he.taxon_concept.in_hierarchy?(hierarchy)
      return nil if he.parent_id == 0
      he = he.parent
    end
    return nil if he.nil? || he.taxon_concept.nil?
    he.taxon_concept.entry(hierarchy)
  end

  def details_hash(language = Language.english)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.
    # TODO - why?!
    return SpeciesSchemaModel.connection.execute("SELECT n1.string scientific_name, n1.italicized scientific_name_italicized, n2.string common_name, n2.italicized common_name_italicized, he.taxon_concept_id id, he.id hierarchy_entry_id, he.hierarchy_id, he.lft lft, he.rgt rgt, he.rank_id, hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image, r.label rank_string FROM hierarchy_entries he JOIN names n1 ON (he.name_id=n1.id) LEFT JOIN hierarchies_content hc ON (he.id=hc.hierarchy_entry_id) LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)) ON (he.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id}) LEFT JOIN ranks r ON (he.rank_id=r.id) WHERE he.id=#{id}").all_hashes[0]
  end
  
  def common_name_details
    result = SpeciesSchemaModel.connection.execute("
        SELECT s.id synonym_id, n.string name_string, l.label language_label, l.iso_639_1
        FROM synonyms s
        JOIN names n ON (s.name_id = n.id)
        LEFT JOIN languages l ON (s.language_id = l.id)
        WHERE s.hierarchy_entry_id = #{self.id}
        AND s.hierarchy_id = #{self.hierarchy_id}
        AND s.synonym_relation_id IN (#{SynonymRelation.common_name_ids.join(',')})").all_hashes

    for r in result
      language_code = ''
      unless r['language_label'].blank?
        language_code = r['iso_639_1'].blank? ? r['language_label'] : r['iso_639_1']
      end
      r['language_code'] = language_code
    end

    result.sort! do |a, b|
      if a['language_code'] == b['language_code']
        a['name_string'] <=> b['name_string']
      else
        a['language_code'].downcase <=> b['language_code'].downcase
      end
    end
  end

  def vet_synonyms(options = {})
    raise "Missing :name_id"     unless options[:name_id]
    raise "Missing :language_id" unless options[:language_id]
    raise "Missing :vetted"      unless options[:vetted]
    Synonym.update_all(
      "vetted_id = #{options[:vetted].id}",
      "language_id = #{options[:language_id]} AND name_id = #{options[:name_id]} AND hierarchy_entry_id = #{id}"
    )
  end

  # TODO - this is an awful name.  Which details?  What is it used for?  Why can't we just use synonyms (the objects)?
  def synonym_details
    result = SpeciesSchemaModel.connection.execute("
        SELECT s.id synonym_id, n.string name_string, sr.label relation
        FROM synonyms s
        JOIN names n ON (s.name_id = n.id)
        LEFT JOIN synonym_relations sr ON (s.synonym_relation_id = sr.id)
        WHERE s.hierarchy_entry_id = #{self.id}
        AND s.hierarchy_id = #{self.hierarchy_id}
        AND s.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})").all_hashes

    for r in result
      r['relation'] ||= ''
    end

    result.sort!{|a,b| a['name_string'] <=> b['name_string'] }
  end

  def details(params = {})
    rank_label = self.rank.nil? ? '' : self.rank.label
    name_string = Rank.italicized_ids.include?(rank_id.to_i) ? self.name_object.italicized.firstcap! : self.name_object.string.firstcap!
    if params[:include_common_names]
      params[:common_name_language] ||= Language.english
      common_names = TaxonConcept.quick_common_names([taxon_concept_id], params[:common_name_language], hierarchy)
      name_string = common_names[taxon_concept_id] unless common_names.blank? || common_names[taxon_concept_id].blank?
    end
    content_level = hierarchies_content ? hierarchies_content.content_level : 0

    the_details = { 'id'  => self.id,
      'hierarchy_id'      => self.hierarchy_id,
      'taxon_concept_id'  => self.taxon_concept_id,
      'name_string'       => name_string,
      'rank_label'        => rank_label,
      'descendants'       => self.rgt - self.lft - 1,
      'has_content'       => content_level > 1 }

    if params[:include_stats]
      the_details['stats'] = HierarchyEntryStat.find_by_hierarchy_entry_id(self.id)
    end

    return the_details
  end

  def ancestor_details(params = {})
    ancestor_ids = ancestors.collect{|a| a.id}
    # for some reason self is in ancestors
    ancestor_ids.delete_if{|id| id == self.id}
    return [] if ancestor_ids.empty?
    result = SpeciesSchemaModel.connection.execute("
      SELECT he.id, he.identifier, he.lft, he.rgt, he.rank_id, he.parent_id, he.hierarchy_id, he.taxon_concept_id, n.string name_string, n.italicized italicized_name, r.label rank_label, hc.content_level
      FROM hierarchy_entries he
      JOIN names n ON (he.name_id = n.id)
      LEFT JOIN ranks r ON (he.rank_id = r.id)
      LEFT JOIN hierarchies_content hc ON (he.id = hc.hierarchy_entry_id)
      WHERE he.id IN (#{ancestor_ids.join(',')})").all_hashes

    if params[:include_common_names]
      params[:common_name_language] ||= Language.english
      common_names = TaxonConcept.quick_common_names(result.collect{|r| r['taxon_concept_id']}, params[:common_name_language], hierarchy)
    end
    if params[:include_stats]
      found_stats = HierarchyEntryStat.find_all_by_hierarchy_entry_id(result.collect{|r| r['id']})
      all_stats = {}
      found_stats.each do |s|
        all_stats[s['hierarchy_entry_id'].to_i] = s
      end
    end
    result.each do |r|
      r['name_string'] = Rank.italicized_ids.include?(r['rank_id'].to_i) ? r['italicized_name'].firstcap! : r['name_string'].firstcap!
      r['descendants'] = r['rgt'].to_i - r['lft'].to_i - 1
      r['has_content'] = r['content_level'].to_i > 1
      r['name_string'] = common_names[r['taxon_concept_id'].to_i] unless common_names.blank? || common_names[r['taxon_concept_id'].to_i].blank?
      r['stats'] = all_stats[r['id'].to_i] unless all_stats[r['id'].to_i].blank?
    end
    result.sort!{|a,b| a['lft'].to_i <=> b['lft'].to_i}
  end

  def children_details(params = {})
    HierarchyEntry.children_details(self.id, params)
  end

  def outlink
    return nil if published != 1 && visibility_id != Visibility.visible.id
    this_hierarchy = hierarchy
    if !source_url.blank?
      return {:hierarchy_entry => self, :hierarchy => this_hierarchy, :outlink_url => source_url }
    elsif !this_hierarchy.outlink_uri.blank?
      # if the hierarchy outlink_uri expects an ID
      if matches = this_hierarchy.outlink_uri.match(/%%ID%%/)
        # .. and the ID exists
        unless identifier.blank?
          return {:hierarchy_entry => self, :hierarchy => this_hierarchy, :outlink_url => this_hierarchy.outlink_uri.gsub(/%%ID%%/, identifier) }
        end
      else
        # there was no %%ID%% pattern in the outlink_uri, but its not blank so its a generic URL for all entries
        return {:hierarchy_entry => self, :hierarchy => this_hierarchy, :outlink_url => this_hierarchy.outlink_uri }
      end
    end
  end
  
  def split_from_concept
    result = connection.execute("SELECT he2.id, he2.taxon_concept_id FROM hierarchy_entries he JOIN hierarchy_entries he2 USING (taxon_concept_id) WHERE he.id=#{self.id}").all_hashes
    unless result.empty?
      entries_in_concept = result.length
      # if there is only one member in the entry's concept there is no need to split it
      if entries_in_concept > 1
        # create a new empty concept
        new_taxon_concept = TaxonConcept.create(:published => self.published, :vetted_id => self.vetted_id, :supercedure_id => 0, :split_from => 0)
        
        # set the concept of this entry to the new concept
        self.taxon_concept_id = new_taxon_concept.id
        self.save!
        
        # update references to this entry to use new concept id
        connection.execute("UPDATE IGNORE taxon_concept_names SET taxon_concept_id=#{new_taxon_concept.id} WHERE source_hierarchy_entry_id=#{self.id}");
        connection.execute("UPDATE IGNORE hierarchy_entries he JOIN random_hierarchy_images rhi ON (he.id=rhi.hierarchy_entry_id) SET rhi.taxon_concept_id=he.taxon_concept_id WHERE he.taxon_concept_id=#{self.id}")
        return new_taxon_concept
      end
    end
    return false
  end

  def taxon_concept_metrics(he_id)
    if he_id
        result = SpeciesSchemaModel.connection.execute("SELECT * From hierarchy_entries he INNER JOIN taxon_concept_metrics tcm ON he.taxon_concept_id = tcm.taxon_concept_id WHERE he.id = #{he_id}").all_hashes
        return result
    end
  end

private

  def ancestors_hash_by_language_id(language_id, options = {})
    SpeciesSchemaModel.connection.execute(%Q{
      SELECT he.id, he.taxon_concept_id, he.taxon_concept_id id, he.id hierarchy_entry_id, he.hierarchy_id,
             he.lft lft, he.rgt rgt, he.rank_id, he.parent_id, 
             n1.string scientific_name, n1.italicized scientific_name_italicized,
             n2.string common_name, n2.italicized common_name_italicized,
             hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image,
             r.label rank_string,
             he_source.hierarchy_id source_hierarchy_id
        FROM hierarchy_entries he
          JOIN names n1 ON (he.name_id = n1.id)
          LEFT JOIN hierarchies_content hc ON (he.id = hc.hierarchy_entry_id)
          LEFT JOIN (taxon_concept_names tcn
                     JOIN names n2 ON (tcn.name_id = n2.id)
                     LEFT JOIN hierarchy_entries he_source ON (tcn.source_hierarchy_entry_id = he_source.id))
            ON (he.taxon_concept_id = tcn.taxon_concept_id
                AND tcn.preferred = 1
                AND tcn.language_id = #{language.id})
          LEFT JOIN ranks r ON (he.rank_id = r.id)
        WHERE he.id = #{id}
    } + options[:ordered] ? 'ORDER BY he.lft ASC' : '').all_hashes
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

  def node_to_hash(node, detail_level)
    species_or_below = (node['rgt'].to_i - node['lft'].to_i == 1)
    name = (detail_level.to_sym == :expert) ? node['scientific_name'].firstcap : (node['common_name'] == nil  ? node['scientific_name'].firstcap : node['common_name'].firstcap)
    #name = node['scientific_name_italicized'] if (species_or_below && (detail_level.to_sym == :expert || node['common_name'] == nil))
    name = node['scientific_name_italicized'] if (Rank.italicized_ids.include?(node['rank_id'].to_i) && (detail_level.to_sym == :expert || node['common_name'] == nil))
    {
      :name => name,
      :italicized => detail_level.to_sym == :expert ? node['scientific_name_italicized'].firstcap : (node['common_name_italicized'] == nil  ? node['scientific_name_italicized'].firstcap : node['common_name_italicized'].firstcap),
      :id => node['id'],
      :hierarchy_id => node['hierarchy_id'].to_i,
      :rank_string => node['rank_string'],
      :hierarchy_entry_id => node['hierarchy_entry_id'],
      :valid => node['content_level'].to_i >= $VALID_CONTENT_LEVEL.to_i,
      :enable => species_or_below ? (node['text'].to_i == 1 || node['image'].to_i == 1) : (node['text'].to_i == 1 || node['image'].to_i == 1 || node['child_image'].to_i == 1)
    }
  end

end
