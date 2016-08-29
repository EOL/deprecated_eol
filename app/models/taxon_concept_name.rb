# This is a denormalized table, based on (published+visible or
# unpublished+preview) names, including the preferred scientific name from each
# associated hierarchy entry, its canonical form, and all synonyms (common or
# not... but, according to the code, NOT including acronyms). If it's a
# canonical form, it has exactly the same string as either a preferred common
# name or a synonym... meaning, if the canonical form of one of those names did
# NOT match the original string, you won't find that canonical form in this
# table. I don't know why that decision was made. :\  TODO: I believe that was
# actually a bug. (Honestly, at the time of this writing, I'm not _exactly_ sure
# how TCN is used. I know it is, and in seveal places, but I don't know well
# enough to determine the ramifications of these decisions. One thing it's used
# for is indexing site search, though.)
#
# NOTE: if the source_hierarchy_entry_id is 0, you are looking at a canonical
# form. Further, scientific names (including canonical forms) have neither a
# language_id (it's 0; this should be expected if you're familiar with the Names
# table) nor a synonym_id (which, again, makes sense: it's not a synonym; it's
# either a canonical form or a preferred scientific name for a hierarchy entry).
#
# ...All of this strikes me as pretty weird, really. :\ This is not how I would
# have build a denormalized table of names per taxon concept. ...Other than for
# search (which we store in Solr), there's never really a need for all these
# types at once... so ... go figure. [shrug]
class TaxonConceptName < ActiveRecord::Base

  self.primary_keys = :taxon_concept_id, :name_id, :source_hierarchy_entry_id,
    :language_id, :synonym_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :source_hierarchy_entry, class_name: HierarchyEntry.to_s
  belongs_to :taxon_concept
  belongs_to :vetted

  scope :preferred, -> { where(preferred: true) }
  scope :non_preferred, -> { where(preferred: false) }
  scope :vernacular, -> { where(vern: true) }
  scope :scientific, -> { where(vern: false) }

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

  def self.rebuild_by_taxon_concept_id(ids)
    TaxonConceptName::Rebuilder.by_taxon_concept_id(ids)
  end

  def to_json_hash
    jhash = { "@language" => language.iso_639_1,
               "@value" => name.string }
    if preferred?
      jhash['gbif:isPreferredName'] = true
    end
    jhash
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
    TaxonConceptName.connection.execute(EOL::Db.sanitize_array([%Q{
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
