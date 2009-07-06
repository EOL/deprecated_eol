class FixNonUserRatings < ActiveRecord::Migration
  def self.up
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id and udor.id=null) set dato.data_rating=3.9 where dato.data_rating>4.0;")
  end

  def self.down
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id and udor.id=null) set dato.data_rating=5.0 where dato.data_rating=3.9;")
  end
end
