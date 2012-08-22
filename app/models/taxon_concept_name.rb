class TaxonConceptName < ActiveRecord::Base

  self.primary_keys = :taxon_concept_id, :name_id, :source_hierarchy_entry_id, :language_id, :synonym_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :source_hierarcy_entry, :class_name => HierarchyEntry.to_s
  belongs_to :taxon_concept
  belongs_to :vetted

  def self.sort_by_language_and_name(taxon_concept_names)
    taxon_concept_names.compact.sort_by do |tcn|
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

  def agents
    all_agents = []
    if synonym
      all_agents += synonym.agents
    elsif source_hierarcy_entry
      all_agents += source_hierarcy_entry.agents
    end
    all_agents.delete(Hierarchy.eol_contributors.agent)
    all_agents.uniq.compact
  end

  def hierarchies
    all_hierarchies = []
    if synonym
      all_hierarchies << synonym.hierarchy unless synonym.hierarchy == Hierarchy.eol_contributors
    elsif source_hierarcy_entry
      all_hierarchies << source_hierarcy_entry.hierarchy unless synonym.hierarchy == Hierarchy.eol_contributors
    end
    all_hierarchies.uniq.compact
  end

end
