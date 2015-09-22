namespace :images do
  desc 'get list of  (scientific name of entity, # of trusted eol.org images)'
  task :count_trusted => :environment do
    batch_size = 10000
    trusted_id = Vetted.trusted.id
    visible_id = Visibility.visible.id
    data = {}
    File.open("public/images_count.json", "wb") do |file|
      file.write("[")
      TaxonConcept.find_each(batch_size: batch_size, conditions: "published = true") do |taxon|
        count = 0
        hes = HierarchyEntry.find_all_by_taxon_concept_id_and_published(taxon.id, true, select: { hierarchy_entries: [ :id, :vetted_id, :hierarchy_id, :taxon_concept_id, :name_id]})
        if ! hes.blank?
          hes.each do |entry|
            count += entry.data_objects.images.count(:conditions => "data_objects_hierarchy_entries.vetted_id = #{trusted_id} and data_objects_hierarchy_entries.visibility_id = #{visible_id}")
          end
          preferred_entry = TaxonConceptPreferredEntry.find_all_by_taxon_concept_id(taxon.id, select:{taxon_concept_preferred_entries:[:hierarchy_entry_id]})
          if ! preferred_entry.blank?
            data[:name] = Name.find(HierarchyEntry.find(preferred_entry.first.hierarchy_entry_id, select: {hierarchy_entries: :name_id}).name_id, select: {names: :string}).string
          else
            data[:name] = HierarchyEntry.sort_by_vetted(hes).first.name.string       
          end
          data[:count] = count
          file.write(data.to_json + ",\n")
        end
      end 
      file.write("]\n")
    end
  end
end