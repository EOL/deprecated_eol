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

namespace :cache do
   desc 'Clear memcache'
   task :clear => :environment do
     $CACHE.clear
     ActionController::Base.cache_store.clear
   end
end
