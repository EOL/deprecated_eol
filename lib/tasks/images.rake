namespace :images do
  desc 'Fix when exemplar image is lost after reharvesting the resource.'
  task :fix_exemplar_images => :environment do
  batch = TaxonConceptExemplarImage.includes(:data_object).
    where(data_objects: { published: false })
  puts "Starting. #{batch.count} image exemplars to process."
  batch.each_with_index do |tcei, i|
    puts "#{i}: #{tcei.id}"
    datao = tcei.data_object
    # get a published version
    other_version = DataObject.find_by_guid_and_published(datao.guid, 1)
    unless other_version
      # if there isn't a published version get the newest version
      other_version = DataObject.where(guid: datao.guid).order('created_at DESC').first
    end
    if other_version.id != datao.id
      puts "  ...fixed #{tcei.id} from #{other_version.id} to #{datao.id}"
      tcei.update_attributes(data_object_id: other_version.id)
    end
  end
  end
end
