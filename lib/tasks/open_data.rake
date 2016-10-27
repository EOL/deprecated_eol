namespace :open_data do
  desc 'file export for opendata.eol.org'
  task :open_data_dump => :environment do |t|

    def get_text_objects(taxon)
      objects = taxon.data_objects_from_solr({published: true,data_type_ids: DataType.text_type_ids,filter_by_subtype: false})
      text_objects = []
      objects.each do |text|
        text_objects << text.attributes.slice('id', 'guid', 'identifier','data_type_id', 'data_subtype_id','mime_type_id','object_title',
                               'language_id','metadata_language_id','license_id','rights_statement','rights_holder','bibliographic_citation',
                               'source_url','description','object_url','thumbnail_url','location','latitude','longitude','altitude',
                               'data_rating','derived_from','spatial_location')
      end
      text_objects.join("\n"+"\n")
    end

    def get_media_objects(taxon)
      objects = taxon.data_objects_from_solr({published: true,data_type_ids: DataType.media_type_ids,filter_by_subtype: false})
      media_objects = []
      objects.each do |media|
        media_objects << media.attributes.slice('id', 'guid', 'identifier','data_type_id', 'data_subtype_id','mime_type_id','object_title',
                               'language_id','metadata_language_id','license_id','rights_statement','rights_holder','bibliographic_citation',
                               'source_url','description','object_url','thumbnail_url','location','latitude','longitude','altitude',
                               'data_rating','derived_from','spatial_location')
      end
      media_objects.join("\n"+"\n")
    end

    def get_hierarchy_entries(taxon_id)
      he = HierarchyEntry.where(taxon_concept_id: taxon_id)
      names =  []
      urls = []
      he.each do |e|
        names << e.name.string
        urls << e.outlink_url
      end
      return he.pluck(:id),names,urls
    end

    def get_traits_and_their_uris(taxon_id)
      traits = PageTraits.new(taxon_id).traits
      uris = []
      traits.each do |trait|
        uris << trait.point.attributes.slice('id', 'uri', 'class_type', 'predicate','object', 'unit_of_measure','resource_id')
      end
      return traits,uris.join("\n"+"\n")
    end

    def open_file(file_index)
     file = File.open("public/open_data.#{file_index}.csv", "wb")
     fill_the_file(file,file_index.to_s)
    end

    def fill_the_file(file_index,index = 0)

       file_index = file_index.to_i
       File.open("public/open_data.#{file_index}.csv", "wb") do |f|
        file_index += 1
        maximum = 20
        batch_size = 10
        batch = []
        header = ['HierarchyEntryId','HierarchyEntryName','HierarchyEntryOutLinkURL','TaxonConceptId',
                  'ScientificName','TextObjects' , 'MediaObjects', 'Traits' , 'Trait_Uris']
        f.write(header.to_csv(:col_sep => "\t"))
        TaxonConcept.published.find_each(start: index+1,batch_size: batch_size) do |taxon|
                     index += 1
                     page = TaxonPage.new(taxon)
                     taxon_name = page.scientific_name
                     traits, uris = get_traits_and_their_uris(taxon.id)
                     he_id,he_name,he_url = get_hierarchy_entries(taxon.id)
                     batch << he_id.map(&:inspect).join(', ')
                     batch << he_name.to_s.gsub('"', '').gsub("nil",'"')
                     batch << he_url.to_s.gsub('"', '').gsub("nil",'"')
                     batch << taxon.id.to_s.gsub('"', '').gsub("nil",'"')
                     batch << taxon_name.to_s.gsub('"', '').gsub("nil",'"')
                     batch << get_text_objects(taxon).to_s.gsub('"', '').gsub("nil",'"')
                     batch << get_media_objects(taxon).to_s.gsub('"', '').gsub("nil",'"')
                     batch << traits.to_s.gsub(',',"\n").gsub('"', '').gsub("nil",'"')
                     batch << uris.to_s.gsub('#',"\n").gsub('"', '').gsub("nil",'"')
                     f.write(batch.to_csv(:col_sep => "\t"))
                     batch  = []
#                      this loop is just for testing
                     if index >30
                      break
                    end
                     if index % maximum == 0 && index < 31
                       fill_the_file(file_index.to_s,index)
                       break
                     end

            end

       end

    end

    puts "Started (#{Time.now})\n"
    file_index = 0
    file = fill_the_file(file_index.to_s)
    print "\n Done \n"
    puts "Ended (#{Time.now})\n"
  end
 end

 # File.open("public/open_data.csv", "wb") do
      # batch_size = 2
      # index = 0
    # CSV.generate({:col_sep=>"\t"}) do |csv|
      # csv << ['HierarchyEntryId','TaxonConcepts', 'TextObjects' , 'MediaObjects', 'Traits' , 'Trait_Uris']  # title row
      # TaxonConcept.published.find_each(batch_size: batch_size) do |taxon|
          # index += 1
          # csv << [HierarchyEntry.where(taxon_concept_id: taxon.id).pluck(:id),taxon.id,taxon.data_objects_from_solr({published: true,data_type_ids: DataType.text_type_ids,filter_by_subtype: false})]
          # if index % batch_size == 0
                        # # batch = []
             # break
          # end
      # end
      # send_file(csv)
    # end
    # end
    # __________________________________________________________________________________________________________
 # File.open("public/open_data.csv", "wb") do |file|
        # file_size = 0
        # maximum = 10
        # index = 0
        # batch_size = 2
        # batch = []
        # data = {}
 # end
# header = ['HierarchyEntryId','HierarchyEntryName','HierarchyEntryOutLinkURL','TaxonConcepts', 'TextObjects' , 'MediaObjects', 'Traits' , 'Trait_Uris']
        # file << header
        # TaxonConcept.published.find_each(batch_size: batch_size) do |taxon|
                    # index += 1
                    # # # file.write("TaxonConcept id\t" + "#{taxon.id}")
                    # # # file.write("Text Objects :")
                    # # # file.puts(taxon.data_objects.texts)
                     # # # file.puts("Media Objects :")
                    # # # file.puts(taxon.data_objects.media)
                    # he = HierarchyEntry.where(taxon_concept_id: taxon.id)
                    # data[:he_id] = he.pluck(:id)
                    # data[:he_name] = []
                    # data[:he_url] = []
                    # he.each do |h|
                      # data[:he_name] << h.name.string
                      # data[:he_url] << h.outlink_url
                    # end
                    # data[:taxon_concepts] = taxon.id
                    # data[:text] = taxon.data_objects_from_solr({published: true,data_type_ids: DataType.text_type_ids,filter_by_subtype: false})
                    # data[:media] = taxon.data_objects_from_solr({published: true,data_type_ids: DataType.media_type_ids,filter_by_subtype: false})
                    # data[:traits] = PageTraits.new(taxon.id).traits
                    # data[:points] = []
                    # data[:traits].each do |t|
                      # data[:points] << t.point
                    # end
                    # # debugger
                    # batch << data[:he_id].to_s
                    # batch << data[:he_name].to_s
                    # batch << data[:he_url].to_s
                    # batch << data[:taxon_concepts].to_s
                    # batch << data[:text].to_s
                    # batch << data[:media].to_s
                    # batch << data[:traits].to_s
                    # batch << data[:points].to_s
                    # # debugger
                    # file << batch
                    # batch  = []
                    # if index % batch_size == 0
                        # batch = []
                        # break
                    # end
            # end
            # print "\n Done \n"
            # puts "Ended (#{Time.now})\n"
  # end

# ________________________________________________________________________________________________________________________
# header = ['TaxonConcepts', 'TextObjects' , 'MediaObjects']
#
        # file.write(header.to_csv(:col_sep => "\t"))
#
            # TaxonConcept.published.find_each(batch_size: batch_size) do |taxon|
                    # index += 1
                    # data[:taxon_concepts] = taxon.id
                    # data[:text] = taxon.data_objects.texts.pluck(:id)
                    # data[:media] = taxon.data_objects.media.pluck(:id)
                    # batch << data[:taxon_concepts].to_s
                    # batch << data[:text].to_s
                    # batch << data[:media].to_s
                    # file.write(batch.to_csv(:col_sep => "\t"))
                    # batch  = []
                    # if index % batch_size == 0
                        # batch = []
                        # break
                    # end
            # end
            # print "\n Done \n"
            # puts "Ended (#{Time.now})\n"
#_____________________________________________________________________________________________________________________________________
# index = 0
      # batch_size = 100
      # # if index <= 10
      # TaxonConcept.published.limit(10).includes(:data_objects).each do |tc|
          # # file.write([HierarchyEntry.where(taxon_concept_id: tc.id).pluck(:id), tc.id, tc.data_objects.where(data_type_id: DataType.text_type_ids).pluck(:id),
                    # # tc.data_objects.where(data_type_id: DataType.media_type_ids).pluck(:id), TraitBank.page_with_traits(tc.id,2)].to_csv)
      # end
      # # index = index+10
      # # end
