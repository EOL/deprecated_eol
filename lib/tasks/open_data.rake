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
        maximum = 100000
        batch_size = 1000
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
#
                     if index % maximum == 0
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
