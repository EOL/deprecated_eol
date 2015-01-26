namespace :images do

  desc 'Fix exemplar images.'
  task :fix_exemplar_images => :environment do
    TaxonConceptExemplarImage.all.each do |tcei|
      datao = DataObject.find(tcei.data_object_id)
      if !datao.published
        # get a published version
        other_version = DataObject.find_by_guid_and_published(datao.guid, 1)
        unless other_version
          # if there isn't a published version get the newest version
          other_version = DataObject.find_by_guid(datao.guid).order('created_at DESC')
        end  
        if other_version.id != datao.id
          tcei.update_attributes(data_object_id: other_version.id)
        end
      end
    end
  end
end
