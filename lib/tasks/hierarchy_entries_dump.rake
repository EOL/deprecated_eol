namespace :hierarchy_entries do
  desc 'hierarchy entries dump'
  task :hierarchy_entries_dump => :environment do
    puts "Started (#{Time.now})\n"
    ncbi_id = Hierarchy.ncbi ? Hierarchy.ncbi.id : -1 
    col_id = Hierarchy.col ? Hierarchy.col.id : -1
    worms_id = Hierarchy.worms ? Hierarchy.worms.id : -1
    File.open("public/hierarchy_entries.csv", "wb") do |file|
      # Headers:
      file.write("he id, tc id, ncbi outlink id, worms outlink id, col outlink id, scientific name, outlink url, outlinks\n")
      index = 0
      batch_size = 1000
      HierarchyEntry.published.find_each(batch_size: batch_size) do |he|
        outlinks = []
        if TaxonConcept.find(he.taxon_concept_id).published?
          TaxonConcept.find(he.taxon_concept_id).published_hierarchy_entries.delete_if{|ent| ent.id == he.id}.each do |entry|
            content_partner_name = he.hierarchy.resource.try(:content_partner).try(:display_name)? content_partner_name : ""
            entry_outlink = {}
            entry_outlink[content_partner_name] = entry.outlink_url ? entry.outlink_url : ""
            outlinks << entry_outlink
          end
        end
        file.write([he.id, he.taxon_concept_id, ncbi_id == he.hierarchy.id ? ncbi_id : "", worms_id == he.hierarchy.id ? worms_id : "", 
          col_id == he.hierarchy.id ? col_id : "", he.name.string, he.outlink_url, outlinks].to_csv)
      end
      print "\n Done \n"
    end
  end
end
