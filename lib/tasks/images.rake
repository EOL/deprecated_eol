namespace :images do
  desc 'get list of  (scientific name of entity, # of trusted eol.org images)'
  task :count_trusted => :environment do
    batch_size = 10000
    trusted_id = Vetted.trusted.id
    visible_id = Visibility.visible.id
    solr_query_parameters = {ignore_translations: true, return_hierarchically_aggregated_objects: true,
      data_type_ids: [1], vetted_types: ['trusted'], visibility_types: ['visible'], get_taxon_concept_ids: true,
      published: 1, preload_select: { data_objects: [:published ] }}
    options = TaxonConcept.default_solr_query_parameters(solr_query_parameters)
    data = {}
    File.open("public/images_count.json", "wb") do |file|
      file.write("[")
      TaxonConceptPreferredEntry.
        includes(published_taxon_concept: { preferred_names: [:name]}).
        find_each(batch_size: batch_size) do |tcpe|
          if tcpe.published_taxon_concept
            data[:name] = tcpe.published_taxon_concept.preferred_names.map { |pn| pn.name.try(:string) }.compact.sort.first
            data[:count]= get_count_from_solr(tcpe.published_taxon_concept.id, options)
            file.write(data.to_json+"\n")
          end
        end
      file.write("]\n")
    end
  end
  
  def get_count_from_solr(id, options)
    count = EOL::Solr::DataObjects.get_image_count(id, options)  
  end
end

