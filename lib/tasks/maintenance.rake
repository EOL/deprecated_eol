require 'zlib'

namespace :dato do
  desc "Recalculate data object ratings"
  task :recalculate_rating => :environment do
    zero_rating_datos = DataObject.find_by_sql("SELECT DISTINCT dato.id, dato.guid, dato.data_rating
                                                  FROM data_objects dato
                                                  JOIN #{UsersDataObjectsRating.full_table_name} udor
                                                  ON (dato.guid = udor.data_object_guid)")
    DataObject.transaction do
      zero_rating_datos.each do |dato|
        dato.recalculate_rating
      end
    end
  end
end

namespace :exemplar_images do
  desc "Update exemplar images to their lastest DataObjects' versions"
  task :refresh => :environment do
    # get all exemplars whose DataObject is not published
    exemplars_needing_updating = TaxonConceptExemplarImage.find_by_sql("
      SELECT exemplar.* FROM taxon_concept_exemplar_images exemplar
      JOIN data_objects do ON (exemplar.data_object_id=do.id) WHERE do.published=0")
    # preload the DataObjects
    TaxonConceptExemplarImage.preload_associations(exemplars_needing_updating, { :data_object => :language })
    
    exemplars_needing_updating.each do |exemplar|
      if !exemplar.data_object.published?
        # if there is a latest version
        if latest = exemplar.data_object.latest_published_version_in_same_language
          # puts "exemplar.data_object_id = #{latest.id}"
          exemplar.data_object_id = latest.id
          exemplar.save!
        else # the image is unpublished AND there is no latest version
          # I suppose we could delete this, but I'll hold off for now. Its possible a new version
          # of the exemplar will be available again in the future
        end
      end
    end
  end
end

namespace :image_crops do
  desc "Undo all image cropping and restore DataObjects to original object_cache_urls"
  task :revert => :environment do
    already_reverted_objects = {}
    all_crops = ImageCrop.order('data_object_id asc, created_at asc')
    all_crops.each do |image_crop|
      next if already_reverted_objects[image_crop.data_object_id]
      image_crop.data_object.update_attribute('object_cache_url', image_crop.original_object_cache_url)
      already_reverted_objects[image_crop.data_object_id] = true
    end
  end
end
