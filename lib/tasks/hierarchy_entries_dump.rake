namespace :hierarchy_entries do
  desc 'hierarchy entries dump'
  task :hierarchy_entries_dump => :environment do
    puts "Started (#{Time.now})\n"
    ncbi_id = Hierarchy.ncbi ? Hierarchy.ncbi.id : -1 
    col_id = Hierarchy.col ? Hierarchy.col.id : -1
    worms_id = Hierarchy.worms ? Hierarchy.worms.id : -1
    File.open("public/hierarchy_entries.csv", "wb") do |file|
      # Headers:
      file.write("he id, tc id, ncbi outlink id, worms outlink id, col outlink id, scientific name, outlink url\n")
      index = 0
      batch_size = 1000
      HierarchyEntry.published.find_each(batch_size: batch_size) do |he|
        if TaxonConcept.find(he.taxon_concept_id).published?
          file.write([he.id, he.taxon_concept_id, ncbi_id == he.hierarchy.id ? ncbi_id : "", worms_id == he.hierarchy.id ? worms_id : "", 
            col_id == he.hierarchy.id ? col_id : "", he.name.string ? he.name.string : "", he.outlink_url ? he.outlink_url : ""].to_csv)
        end
      end
    end
  end
end
