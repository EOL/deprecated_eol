class TaxonConceptName < ActiveRecord::Base

  self.primary_keys = :taxon_concept_id, :name_id, :source_hierarchy_entry_id, :language_id, :synonym_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :source_hierarchy_entry, class_name: HierarchyEntry.to_s
  belongs_to :taxon_concept
  belongs_to :vetted

  def can_be_deleted_by?(user)
    agents.map(&:user).include?(user)
  end

  def self.sort_by_language_and_name(taxon_concept_names)
    taxon_concept_names.compact.sort_by do |tcn|
      language_iso = tcn.language.blank? ? '' : tcn.language.iso_639_1
      [language_iso,
       tcn.preferred * -1,
       tcn.name.try(:string)]
    end
  end

  def to_jsonld
    jsonld = { '@type' => 'gbif:VernacularName',
                          'dwc:vernacularName' => { language.iso_639_1 => name.string },
                          'dwc:taxonID' => KnownUri.taxon_uri(taxon_concept_id) }
    if preferred?
      jsonld['gbif:isPreferredName'] = true
    end
    jsonld
  end

  # TODO - why pass in by_whom, here? We don't use it. I'm assuming it's a
  # duck-type for now and leaving it, but... TODO - we should actually update
  # the instance, not just the DB. True, in practice we don't care, but it
  # hardly violates the principle of least surprise (I wasted 15 minutes with a
  # test because of it).
  def vet(vet_obj, by_whom)
    raw_update_attribute(:vetted_id, vet_obj.id)
    # We don't want untrusted names to be preferred:
    raw_update_attribute(:preferred, 0) if vet_obj == Vetted.untrusted
    # There *are* TCNs in prod w/o synonyms (from CoL, I think)
    synonym.update_attributes!(vetted: vet_obj) if synonym
  end

  # Our composite primary keys gem is too stupid to handle this change
  # correctly, so we're bypassing it here:
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

  def agents
    all_agents = []
    if synonym
      all_agents += synonym.agents
    elsif source_hierarchy_entry
      all_agents += source_hierarchy_entry.agents
    end
    all_agents.delete(Hierarchy.eol_contributors.agent)
    all_agents.uniq.compact
  end

  def hierarchies
    all_hierarchies = []
    if synonym
      all_hierarchies << synonym.hierarchy unless synonym.hierarchy == Hierarchy.eol_contributors
    elsif source_hierarchy_entry
      all_hierarchies << source_hierarchy_entry.hierarchy unless source_hierarchy_entry.hierarchy == Hierarchy.eol_contributors
    end
    all_hierarchies.uniq.compact
  end

end
