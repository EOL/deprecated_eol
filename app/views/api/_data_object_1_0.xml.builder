unless data_object_hash.blank?
  xml.dataObject do
    xml.dataObjectID data_object_hash['identifier']
    unless taxon_concept_id.blank?
      xml.taxonConceptID taxon_concept_id
    end
    xml << render(partial: 'data_object_metadata', layout: false, locals: { :data_object_hash => data_object_hash } )
  end
end
