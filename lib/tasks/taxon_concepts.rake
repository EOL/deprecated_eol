require "csv"
namespace :taxon_concepts do
  desc 'generate csv'
  task :generate_csv => :environment do
    CSV.open("common_names.csv", "wb") do |csv|
      csv << ["taxon_concept_id", "rank", "ancestors_taxon_concepts_ids", "preferred_scientific_names", "preferred_common_names",
              "hierarchy_entry_id", "resource_name", "content_provider_name", "identifier"]
      # TODO add limit and offset
      TaxonConcept.published.find_each do |tc|
        taxon_concept_id = tc.id
        
        rank = ""
        ancestors_taxon_concepts_ids = []
        pe = tc.entry
        if pe
          r = pe.rank
          rank = r.label if r
          ancestors = pe.ancestors
          ancestors_taxon_concepts_ids = ancestors.select([:taxon_concept_id]).map(&:taxon_concept_id) if ancestors
        end
        
        preferred_scientific_names = tc.preferred_names.collect{|p| p.name.string}
       
        preferred_common_names = tc.preferred_common_names.collect{|p| "#{p.language.iso_639_1}:#{p.name.string}"}
        
        hierarchy_entry_id = nil
        resource_name = nil
        content_provider_name = nil
        identifier = nil
                      
        csv << [taxon_concept_id, rank, ancestors_taxon_concepts_ids.join(","), preferred_scientific_names.join(","), preferred_common_names.join(","),
               hierarchy_entry_id, resource_name, content_provider_name, identifier]
        tc.hierarchy_entries.each do |he|
          hierarchy_entry_id = he.id
          hehe = HarvestEventsHierarchyEntry.where(hierarchy_entry_id: he.id).order('harvest_event_id DESC').limit(1).first
          if hehe
            h = HarvestEvent.find(hehe.harvest_event_id)
            res = Resource.find(h.resource_id) if h
            if res
              resource_name = res.title
              content_provider_name = ContentPartner.find(res.content_partner_id).display_name
            end
          end
          identifier = he.identifier
          csv << ["", "", "", "", "", hierarchy_entry_id, resource_name, content_provider_name, identifier]
        end
      end       
      puts "done"
    end
  end
end