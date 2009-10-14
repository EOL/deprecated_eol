class ChangeUsersDataObjectsRatings < ActiveRecord::Migration
  #to change old existing data
  
  def self.up
    execute "update users_data_objects_ratings u join #{DataObject.full_table_name} d on d.id=u.data_object_id set data_object_guid = d.guid"
    val = execute "select d.guid, user_id from users_data_objects_ratings u join #{DataObject.full_table_name} d on d.id=u.data_object_id group by d.guid, user_id having count(*) > 1"
    #remove_column :users_data_objects_ratings, :data_object_id
    val.each do |guid, user_id|
     u = UsersDataObjectsRating.find_all_by_user_id_and_data_object_guid(user_id, guid, :order => 'data_object_id')
     u[0...-1].each do |udor|
        udor.destroy
      end
    end
    add_index :users_data_objects_ratings, [:data_object_guid, :user_id], :name => 'idx_users_data_objects_ratings_1'
  end

  def self.down
    # we can't restore data for data_object_id column :-(
    #add_column :users_data_objects_ratings, :data_object_id, :integer 
    remove_index :users_data_objects_ratings, :name => 'idx_users_data_objects_ratings_1'
  end
end
