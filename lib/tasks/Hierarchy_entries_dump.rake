namespace :hierarchy_entries do
  desc 'hierarchy entries dump'
  task :hierarchy_entries_dump => :environment do
    puts "Started (#{Time.now})\n"
    # Cache the ranks so we're not constantly looking them up:
    ncbi_id = Hierarchy.ncbi ? Hierarchy.ncbi.id : -1 
    col_id = Hierarchy.col ? Hierarchy.col.id : -1
    worms_id = Hierarchy.worms ? Hierarchy.worms.id : -1
    File.open("public/hierarchy_entries.json", "wb") do |file|
      # Headers:
      file.write("[")
      index = 0
      batch_size = 1000
      HierarchyEntry.published.find_each(batch_size: batch_size) do |he|
        data = {}
        data[:he_id] = he.id
        data[:tc_id] = he.taxon_concept_id
        data[:ncbi_outlink_id] = ncbi_id == he.hierarchy.id ? ncbi_id : ""
        data[:worms_outlink_id] = worms_id == he.hierarchy.id ? worms_id : ""
        data[:col_outlink_id] = col_id == he.hierarchy.id ? col_id : ""
        data[:scientnific_name] = he.italicized_name.firstcap
        data[:outlink_url] = he.outlink_url
        
        file.write(data.to_json + ",\n")
      end
      file.write("]\n")
      print "\n Done \n"
    end
  end
end
