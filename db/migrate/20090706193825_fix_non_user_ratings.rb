class FixNonUserRatings < ActiveRecord::Migration
  def self.up
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id) set dato.data_rating=3.9 where dato.data_rating>3.9 and udor.id IS NULL;")
  end

  def self.down
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id) set dato.data_rating=5.0 where dato.data_rating=3.9 and udor.id IS NULL;")
  end
end
