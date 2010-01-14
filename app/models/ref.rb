class Ref < SpeciesSchemaModel

  has_many :ref_identifiers
  belongs_to :visibility
  
  has_and_belongs_to_many :data_objects
  has_and_belongs_to_many :taxa

  # Returns a list of Literature References. Will return an empty array if there aren't any results
  def self.find_refs_for(taxon_concept_id)
    refs = Ref.find_by_sql([
      " SELECT refs.* FROM hierarchy_entries he 
                  JOIN taxa t ON (he.id=t.hierarchy_entry_id) 
                  JOIN data_objects_taxa dot ON (t.id=dot.taxon_id) 
                  JOIN data_objects do ON (dot.data_object_id=do.id)
                  JOIN data_objects_refs dor ON (dot.data_object_id=dor.data_object_id) 
                  JOIN refs ON (dor.ref_id=refs.id)
                  WHERE he.taxon_concept_id=?
                  AND do.published=1
                  AND do.visibility_id=?
                  AND refs.published=1
                  AND refs.visibility_id=?
        UNION
        SELECT refs.* FROM hierarchy_entries he 
                    JOIN taxa t ON (he.id=t.hierarchy_entry_id) 
                    JOIN refs_taxa rt ON (t.id=rt.taxon_id) 
                    JOIN refs ON (rt.ref_id=refs.id)
                    WHERE he.taxon_concept_id=?
                    AND he.published=1
                    AND refs.published=1
                    AND refs.visibility_id=?
                    ", taxon_concept_id, Visibility.visible.id, Visibility.visible.id, taxon_concept_id, Visibility.visible.id])
  end

  # Determines whether or not the TaxonConcept has Literature References
  def self.literature_references_for?(taxon_concept_id)
    # a. TC -> HE -> T -> data_objects_taxa -> data_objects -> data_objects_refs -> refs       
    # b. tc -> he -> taxa -> refs_taxa
    ref_count = Ref.count_by_sql([
      "SELECT 1 FROM hierarchy_entries he 
                JOIN taxa t ON (he.id=t.hierarchy_entry_id) 
                JOIN data_objects_taxa dot ON (t.id=dot.taxon_id) 
                JOIN data_objects do ON (dot.data_object_id=do.id)
                JOIN data_objects_refs dor ON (dot.data_object_id=dor.data_object_id) 
                JOIN refs ON (dor.ref_id=refs.id)
                WHERE he.taxon_concept_id=?
                AND do.published=1
                AND do.visibility_id=?
                AND refs.published=1
                AND refs.visibility_id=?
                LIMIT 1
      UNION
      SELECT 1 FROM hierarchy_entries he 
                JOIN taxa t ON (he.id=t.hierarchy_entry_id) 
                JOIN refs_taxa rt ON (t.id=rt.taxon_id) 
                JOIN refs ON (rt.ref_id=refs.id)
                WHERE he.taxon_concept_id=?
                AND he.published=1
                AND refs.published=1
                AND refs.visibility_id=?
                LIMIT 1", taxon_concept_id, Visibility.visible.id, Visibility.visible.id, taxon_concept_id, Visibility.visible.id])
    ref_count > 0
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: refs
#
#  id             :integer(4)      not null, primary key
#  full_reference :string(400)     not null

