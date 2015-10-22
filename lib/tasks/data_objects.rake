namespace :data_objects do
  desc 'count'
  task :count => :environment do
    # File.open("public/data_objects_count.json", "wb") do |file|
      # file.write("[")
      str = ""
      url = $SOLR_SERVER +'data_objects' +'/select/?wt=json&q='+ CGI.escape(%Q[{!lucene}])
      Resource.all.each do |res|
         temp = res.latest_published_harvest_event
         if temp 
            db_count = temp.data_objects.collect{|ob| ob.id if ob.published}.count
            if db_count > 0
              lucene_query = "resource_id: #{res.id}"
              url << CGI.escape(%Q[(#{lucene_query})])
              resp = open(url).read
              resp = JSON.load(resp)
              solr_count = resp['response']['numFound']
              str += "res = #{res.id}, db = #{db_count}, solr = #{solr_count}\n"  
            end
            str += "res = #{res.id}\n"
          else
              str += "res = #{res.id}\n"
         end
      end
      puts str
      # file.write("]\n")
      print "\n Done \n"
    # end
  end
  
  desc 'count'
  task :has_concepts => :environment do
    # File.open("public/data_objects_count.json", "wb") do |file|
      # file.write("[")
      str = ""
      url = $SOLR_SERVER +'data_objects' +'/select/?wt=json&q='+ CGI.escape(%Q[{!lucene}])
      Resource.all.each do |res|
        res = Resource.find(44)
         temp = res.latest_published_harvest_event
         if temp 
            objs = temp.data_objects.map(&:id)
            db_count = objs.count
            taxon_count = DataObjectsHierarchyEntry.where(data_object_id: Array(objs)).count
            str += "res = #{res.id}, db = #{db_count}, taxon = #{taxon_count}\n"
          else
              str += "res = #{res.id}\n"
         end
      end
      puts str
      # file.write("]\n")
      print "\n Done \n"
    # end
  end
  
  
  
  
  desc 'get list of  (scientific name of entity, # of trusted eol.org images)'
  task :count_trusted => :environment do
    batch_size = 10000
    trusted_id = Vetted.trusted.id
    visible_id = Visibility.visible.id
    data = {}
    File.open("public/images_count.json", "wb") do |file|
      file.write("[")
      taxon = TaxonConcept.find(791464)
        count = 0
        hes = HierarchyEntry.find_all_by_taxon_concept_id_and_published(taxon.id, true, select: { hierarchy_entries: [ :id, :vetted_id, :hierarchy_id, :taxon_concept_id, :name_id]})
        if ! hes.blank?
          hes.each do |entry|
            count += entry.data_objects.images.count(:conditions => "published = 1")
          end
          preferred_entry = TaxonConceptPreferredEntry.find_all_by_taxon_concept_id(taxon.id, select:{taxon_concept_preferred_entries:[:hierarchy_entry_id]})
          if ! preferred_entry.blank?
            data[:name] = Name.find(HierarchyEntry.find(preferred_entry.first.hierarchy_entry_id, select: {hierarchy_entries: :name_id}).name_id, select: {names: :string}).string
          else
            data[:name] = HierarchyEntry.sort_by_vetted(hes).first.name.string       
          end
          data[:count] = count
          # file.write(data.to_json + ",\n")
        end
      end 
      file.write("]\n")
    end
  end
end