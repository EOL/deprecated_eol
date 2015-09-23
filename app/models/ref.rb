# TODO - rename this. It's a reserved word.  :|
class Ref < ActiveRecord::Base

  has_many :ref_identifiers
  belongs_to :visibility

  has_and_belongs_to_many :data_objects
  has_and_belongs_to_many :hierarchy_entries
  has_and_belongs_to_many :collection_items

  before_save :default_visibility

  # this method is not just sorting by rating
  def self.sort_by_full_reference(refs)
    find_starting_nums = 
    refs.sort_by do |r|
      # TODO: is there a better way to stip tags, or sort both strings and numbers here?
      stripped_full_reference = Sanitize.clean(r.full_reference)
      if stripped_full_reference =~ /^\s*(\d+)/
        $1
      else
        stripped_full_reference
      end
    end
  end

  # Returns a list of Literature References. Will return an empty array if there aren't any results
  def self.find_refs_for(taxon_concept_id)
    # refs for DataObjects then HierarchyEntries
    # TODO - This query needs to be reviewed as a result of the WEB-2500
    refs = Ref.find_by_sql([
      " SELECT refs.* FROM hierarchy_entries he
                  JOIN data_objects_hierarchy_entries dohe ON (he.id = dohe.hierarchy_entry_id)
                  LEFT JOIN curated_data_objects_hierarchy_entries cdohe ON
                    (dohe.data_object_id = cdohe.data_object_id
                      AND dohe.hierarchy_entry_id = cdohe.hierarchy_entry_id)
                  JOIN data_objects do ON (dohe.data_object_id = do.id)
                  JOIN data_objects_refs dor ON (do.id = dor.data_object_id)
                  JOIN refs ON (dor.ref_id = refs.id)
                  WHERE he.taxon_concept_id = ?
                  AND do.published = 1
                  AND (dohe.visibility_id = ? OR cdohe.visibility_id = ?)
                  AND refs.published = 1
                  AND refs.visibility_id = ?
        UNION
        SELECT refs.* FROM hierarchy_entries he
                  JOIN hierarchy_entries_refs her ON (he.id=her.hierarchy_entry_id)
                  JOIN refs ON (her.ref_id=refs.id)
                  WHERE he.taxon_concept_id=?
                  AND he.published=1
                  AND refs.published=1
                  AND refs.visibility_id=?
        UNION
        SELECT refs.* FROM #{UsersDataObject.full_table_name} udo
                  JOIN data_objects do ON (udo.data_object_id=do.id)
                  JOIN data_objects_refs dor ON (do.id=dor.data_object_id)
                  JOIN refs ON (dor.ref_id=refs.id)
                  WHERE udo.taxon_concept_id=?
                  AND udo.visibility_id = ?
                  AND do.published=1
                  AND refs.published=1
                  AND refs.visibility_id=?", taxon_concept_id, Visibility.get_visible.id, Visibility.get_visible.id, Visibility.get_visible.id, taxon_concept_id, Visibility.get_visible.id, taxon_concept_id, Visibility.get_visible.id, Visibility.get_visible.id])
  end

  # Determines whether or not the TaxonConcept has Literature References
  def self.literature_references_for?(taxon_concept_id)
    # DataObject references
    ref_count = Ref.count_by_sql([
      "SELECT 1 FROM hierarchy_entries he
                JOIN data_objects_hierarchy_entries dohe ON (he.id=dohe.hierarchy_entry_id)
                LEFT JOIN curated_data_objects_hierarchy_entries cdohe ON
                  (dohe.data_object_id = cdohe.data_object_id
                    AND dohe.hierarchy_entry_id = cdohe.hierarchy_entry_id)
                JOIN data_objects do ON (dohe.data_object_id=do.id)
                JOIN data_objects_refs dor ON (do.id=dor.data_object_id)
                JOIN refs ON (dor.ref_id=refs.id)
                WHERE he.taxon_concept_id=?
                AND do.published=1
                AND (dohe.visibility_id = ? OR cdohe.visibility_id = ?)
                AND refs.published=1
                AND refs.visibility_id=?
                LIMIT 1", taxon_concept_id, Visibility.get_visible.id, Visibility.get_visible.id, Visibility.get_visible.id])
    return true if ref_count > 0

    # HierarchyEntry references
    ref_count = Ref.count_by_sql([
      "SELECT 1 FROM hierarchy_entries he
                JOIN hierarchy_entries_refs her ON (he.id=her.hierarchy_entry_id)
                JOIN refs ON (her.ref_id=refs.id)
                WHERE he.taxon_concept_id=?
                AND he.published=1
                AND refs.published=1
                AND refs.visibility_id=?
                LIMIT 1", taxon_concept_id, Visibility.get_visible.id])
    return true if ref_count > 0

    # User DataObject references
    ref_count = Ref.count_by_sql([
      "SELECT 1 FROM #{UsersDataObject.full_table_name} udo
                JOIN data_objects do ON (udo.data_object_id=do.id)
                JOIN data_objects_refs dor ON (do.id=dor.data_object_id)
                JOIN refs ON (dor.ref_id=refs.id)
                WHERE udo.taxon_concept_id=?
                AND do.published=1
                AND refs.published=1
                AND refs.visibility_id=?
                LIMIT 1", taxon_concept_id, Visibility.get_visible.id])
    ref_count > 0
  end

  private

  def default_visibility
    self.visibility ||= Visibility.get_visible
  end

end
