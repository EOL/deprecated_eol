class FixNonUserRatings < ActiveRecord::Migration
  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id) set dato.data_rating=3.9 where dato.data_rating>3.9 and udor.id IS NULL;")
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    EOL::DB::toggle_eol_data_connections(:eol_data)
    execute("update #{DataObject.full_table_name} dato left join #{UsersDataObjectsRating.full_table_name} udor on (udor.data_object_id=dato.id) set dato.data_rating=5.0 where dato.data_rating=3.9 and udor.id IS NULL;")
    EOL::DB::toggle_eol_data_connections(:eol)
  end
end
