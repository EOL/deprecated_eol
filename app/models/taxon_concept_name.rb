class TaxonConceptName < ActiveRecord::Base

  set_primary_keys :taxon_concept_id, :name_id, :source_hierarchy_entry_id, :language_id, :synonym_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :source_hierarcy_entry, :class_name => HierarchyEntry.to_s
  belongs_to :taxon_concept
  belongs_to :vetted

  def self.sort_by_language_and_name(taxon_concept_names)
    taxon_concept_names.sort_by do |tcn|
      language_iso = tcn.language.blank? ? '' : tcn.language.iso_639_1
      [language_iso,
       tcn.preferred * -1,
       tcn.name.string]
    end
  end

  def vet(vet_obj, by_whom)
    raw_update_attribute(:vetted_id, vet_obj.id)
    synonym.update_attributes!(:vetted => vet_obj) if synonym # There *are* TCNs in prod w/o synonyms (from CoL, I think)
  end

  # Our composite primary keys gem is too stupid to handle this change correctly, so we're bypassing it here:
  def raw_update_attribute(key, val)
    raise "Invalid key" unless self.respond_to? key
    TaxonConceptName.connection.execute(ActiveRecord::Base.sanitize_sql_array([%Q{
      UPDATE `#{self.class.table_name}`
      SET `#{key}` = ?
      WHERE name_id = ?
        AND taxon_concept_id = ?
        AND source_hierarchy_entry_id = ?
    }, val, self[:name_id], self[:taxon_concept_id], self[:source_hierarchy_entry_id]]))
  end

  def sources
    all_sources = []
    if synonym
      all_sources += synonym.agents
      all_sources << synonym.hierarchy.agent
    elsif source_hierarcy_entry
      all_sources += source_hierarcy_entry.agents
      all_sources << source_hierarcy_entry.hierarchy.agent
    end
    all_sources.delete(Hierarchy.eol_contributors.agent)
    all_sources.uniq!
    all_sources.compact!

    # This is *kind of* a hack.  Long, long ago, we kinda mangled our data by not having synonym IDs
    # for uBio names, so uBio became the 'default' common name provider
    if all_sources.blank?
      all_sources << Agent.find($AGENT_ID_OF_DEFAULT_COMMON_NAME_SOURCE) rescue nil
    end
    all_sources
  end

end
