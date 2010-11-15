class TaxonConceptName < SpeciesSchemaModel

  set_primary_keys :name_id, :taxon_concept_id, :source_hierarchy_entry_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :taxon_concept
  belongs_to :vetted

  def vet(vet_obj, by_whom)
    update_attributes!(:vetted => vet_obj)
    synonym.update_attributes!(:vetted => vet_obj)
    by_whom.track_curator_activity(self, 'taxon_concept_name', vet_obj.to_action)
  end

end
