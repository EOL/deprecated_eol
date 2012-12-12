# Represents an entry in the Tree of Life (see Hierarchy).  This is one of the major models of the EOL codebase, and
# most data links to these instances.
class HierarchyEntry < ActiveRecord::Base

  attr_accessor :associated_by_curator # TODO - extract Association class; this is currently used only for them.

  belongs_to :hierarchy
  belongs_to :name
  belongs_to :rank
  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility
  belongs_to :parent, :class_name => HierarchyEntry.to_s, :foreign_key => :parent_id

  has_many :agents, :through => :agents_hierarchy_entries
  has_many :agents_hierarchy_entries
  has_many :top_images
  has_many :top_unpublished_images
  has_many :synonyms
  has_many :scientific_synonyms, :class_name => Synonym.to_s,
      :conditions => Proc.new { "synonyms.synonym_relation_id NOT IN (#{SynonymRelation.common_name_ids.join(',')})" }
  has_many :common_names, :class_name => Synonym.to_s,
      :conditions => Proc.new { "synonyms.synonym_relation_id IN (#{SynonymRelation.common_name_ids.join(',')})" }
  has_many :flattened_ancestors, :class_name => HierarchyEntriesFlattened.to_s
  has_many :curator_activity_logs
  has_many :hierarchy_entry_moves

  has_and_belongs_to_many :data_objects
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :published_refs, :class_name => Ref.to_s, :join_table => 'hierarchy_entries_refs',
    :association_foreign_key => 'ref_id', :conditions => Proc.new { "published=1 AND visibility_id=#{Visibility.visible.id}" }
  has_and_belongs_to_many :ancestors, :class_name => HierarchyEntry.to_s, :join_table => 'hierarchy_entries_flattened',
    :association_foreign_key => 'ancestor_id', :order => 'lft'
  # Here is a way to find children and sort by name at the same time (this works for siblings too):
  # HierarchyEntry.find(38802334).children.includes(:name).order('names.string').limit(2)
  has_many :children, :class_name => HierarchyEntry.to_s, :foreign_key => [:parent_id, :hierarchy_id], :primary_key => [:id, :hierarchy_id],
    :conditions => Proc.new { "`hierarchy_entries`.`visibility_id` IN (#{Visibility.visible.id}, #{Visibility.preview.id}) AND `hierarchy_entries`.`parent_id` != 0" }
  # IMPORTANT: siblings will also return the entry itself. This is because it is not possible to use conditions which refer
  # to a single node when using this association in preloading. For example you cannot have a condition: where id != #{id}, because
  # ActiveRecord may not have a single 'id', it may have many if preloading for multiple entries at once. This will also not return siblings of
  # top level taxa. This is because many hierarchies have hundreds or thousands of roots and we don't want to risk showing all of them
  has_many :siblings, :class_name => HierarchyEntry.to_s, :foreign_key => [:parent_id, :hierarchy_id], :primary_key => [:parent_id, :hierarchy_id],
    :conditions => Proc.new { "`hierarchy_entries`.`visibility_id` IN (#{Visibility.visible.id}, #{Visibility.preview.id}) AND `hierarchy_entries`.`parent_id` != 0" }

  has_one :hierarchy_entry_stat

  def self.sort_by_name(hierarchy_entries)
    hierarchy_entries.sort_by{ |he| he.name.string.downcase }
  end

  def self.sort_by_vetted(hierarchy_entries)
    hierarchy_entries.sort_by do |he|
      vetted_view_order = he.vetted.blank? ? 0 : he.vetted.view_order
      browsable = he.hierarchy.browsable? ? 0 : 1
      published = he.published? ? 0 : 1
      [published,
       vetted_view_order,
       browsable,
       he.taxon_concept_id,
       he.id]
    end
  end

  # If you want to make a browsable tree of HEs, this might be a helpful method:
  def self.preload_deeply_browsable(set)
    HierarchyEntry.preload_associations(set, [ { :agents_hierarchy_entries => :agent }, :rank, { :hierarchy => :agent } ], :select => {:hierarchy_entries => [:id, :parent_id, :taxon_concept_id]} )
    set
  end

  def has_parent?
    self.parent_id && self.parent_id.to_i > 0
  end

  # this method will return either the original name string, or if the rank of the taxon
  # is one to be italicized, the italicized form of the original name string
  def italicized_name
    if name.is_surrogate_or_hybrid? || name.is_subgenus?
      name.string
    else
      species_or_below? ? name.italicized : name.string
    end
  end

  # this method is probably unnecessary and just returns the canonical_form of
  # the original name string - which might very well be nil
  def canonical_form
    return name.canonical_form
  end

  def title_canonical
    return @title_canonical unless @title_canonical.nil?
    # used the ranked version first
    if name.is_surrogate_or_hybrid? || name.is_subgenus?
      @title_canonical = name.string.firstcap
    elsif name.ranked_canonical_form && !name.ranked_canonical_form.string.blank?
      @title_canonical = name.ranked_canonical_form.string.firstcap
    # otherwise bare canonical form
    elsif name.canonical_form && !name.canonical_form.string.blank?
      @title_canonical = name.canonical_form.string.firstcap
    # finally just the name string
    else
      @title_canonical = name.string.firstcap
    end
    @title_canonical
  end

  # takes the result of the above and adds italics tags around it if the 
  # taxon is of a rank which should be italicized
  def title_canonical_italicized
    return @title_canonical_italicized unless @title_canonical_italicized.nil?
    @title_canonical_italicized = title_canonical
    # used the ranked version first
    if name.is_surrogate_or_hybrid? || name.is_subgenus?
      # do nothing
    elsif name.ranked_canonical_form && !name.ranked_canonical_form.string.blank?
      @title_canonical_italicized = "<i>#{@title_canonical_italicized}</i>" if (species_or_below? || @title_canonical_italicized.match(/ /))
    elsif name.canonical_form && !name.canonical_form.string.blank?
      @title_canonical_italicized = "<i>#{@title_canonical_italicized}</i>" if (species_or_below? || @title_canonical_italicized.match(/ /))
    else
      # do nothing
    end
    @title_canonical_italicized
  end

  def rank_label
    if rank.blank? || rank.label.blank?
      I18n.t(:taxon).firstcap
    else
      rank.label.firstcap
    end
  end

  # wrapper function used in options_from_collection_for_select
  def hierarchy_label
    hierarchy.label
  end

  # Returns true IFF this HE was included in a set of HEs because a curator added the association.  See
  # DataObject.curated_hierarchy_entries
  def by_curated_association?
    @associated_by_curator
  end

  def associated_by_curator=(who)
    @associated_by_curator = who
  end

  def associated_by_curator
    @associated_by_curator
  end

  # Duck-typed method for curation, don't change unless you know what you're doing. :)  TODO - extract to class
  def curatable_object(data_object)
    if associated_by_curator
      CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(data_object.guid, id)
    else
      DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(data_object.latest_published_version_in_same_language.id, id)
    end
  end

  def can_be_deleted_by?(requestor)
    return true if by_curated_association? && (requestor.master_curator? || associated_by_curator == requestor)
  end

  def species_or_below?
    return false if rank_id == 0  # this was causing a lookup for rank id=0, so I'm trying to save queries here
    return Rank.italicized_ids.include?(rank_id)
  end

  def kingdom
    return ancestors.first rescue nil
  end

  # Some HEs have a "source database" agent, which needs to be considered in addition to normal sources.
  def source_database_agents
    @source_db_agents ||=
      agents_hierarchy_entries.select {|ar| ar.agent_role_id == AgentRole.source_database.id }.map(&:agent)
  end

  # If a HE *does* have a source database, some behavior changes (we must consider the hierarchy agent source
  # separately), so:
  def has_source_database?
    source_database_agents && ! source_database_agents.empty?
  end

  # These are all of the agents, NOT including the hierarchy agent:
  def source_agents
    agents_hierarchy_entries.select {|ar| ar.agent_role_id == AgentRole.source.id }.map(&:agent)
  end

  # This gives you the correct array of source agents that recognize the taxon.  Keep in mind that if there is a
  # source database, you MUST cite the hierarchy agent SEPARATELY, so it is not included; otherwise, it is:
  def recognized_by_agents
    if has_source_database?
      (source_database_agents + source_agents).compact
    else
      ([hierarchy.agent] + source_agents).compact
    end
  end

  # This is a full list of AgentsHierarchyEntry models associated with this HE, and should only be used when you know
  # there is no source database (the API code uses this method a lot, at the time of this writing).
  def agents_roles
    ([agent_from_hierarchy] + agents_hierarchy_entries).compact
  end

  # This is only used by #agents_roles, to add it to the list when it's actually there. Don't use this to get an Agent.
  def agent_from_hierarchy
    if h_agent = hierarchy.agent
      h_agent.full_name = hierarchy.label # To change the name from just "Catalogue of Life"
      AgentsHierarchyEntry.new(:hierarchy_entry => self, :agent => h_agent,
                               :agent_role => AgentRole.source, :view_order => 0)
    else
      nil
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

  def number_of_descendants
    rgt - lft - 1
  end

  def is_leaf?
    return (rgt-lft == 1)
  end

  def common_name_in_language(language)
    preferred_in_language = taxon_concept.preferred_common_names.select{|tcn| tcn.language_id == language.id}
    return name.string if preferred_in_language.blank?
    preferred_in_language[0].name.string.firstcap
  end

  def preferred_classification_summary
    Rails.cache.fetch(HierarchyEntry.cached_name_for("preferred_classification_summary_for_#{self.id}"), :expires_in => 5.days) do
      HierarchyEntry.preload_associations(self, { :flattened_ancestors => :ancestor }, :select =>
        { :hierarchy_entries => [ :id, :name_id, :rank_id, :taxon_concept_id, :lft, :rgt ] })
      return '' if flattened_ancestors.blank?
      root_ancestor, immediate_parent = kingdom_and_immediate_parent
      str_to_return = root_ancestor.name.string
      str_to_return += " > " + immediate_parent.name.string if immediate_parent
      str_to_return
    end
  end

  def kingdom_and_immediate_parent
    return [ nil, nil ] if flattened_ancestors.blank?
    sorted_ancestors = flattened_ancestors.sort{ |a,b| a.ancestor.lft <=> b.ancestor.lft }
    root_ancestor = sorted_ancestors.first.ancestor
    immediate_parent = sorted_ancestors.pop.ancestor
    while immediate_parent && immediate_parent != root_ancestor && [ Rank.genus.id, Rank.species.id, Rank.subspecies.id, Rank.variety.id, Rank.infraspecies.id ].include?(immediate_parent.rank_id)
      immediate_parent = sorted_ancestors.pop.ancestor
    end
    immediate_parent = nil if immediate_parent == root_ancestor
    entries_to_return = [root_ancestor, immediate_parent]
    HierarchyEntry.preload_associations(entries_to_return, :name)
    entries_to_return
  end


end
