class AddFieldsToDataPointUris < ActiveRecord::Migration
  def change
    add_column :data_point_uris, :class_type, :string
    add_column :data_point_uris, :predicate, :string
    add_column :data_point_uris, :object, :string
    add_column :data_point_uris, :unit_of_measure, :string
    add_column :data_point_uris, :resource_id, :integer
    add_column :data_point_uris, :user_added_data_id, :integer
    add_column :data_point_uris, :predicate_known_uri_id, :integer
    add_column :data_point_uris, :object_known_uri_id, :integer
    add_column :data_point_uris, :unit_of_measure_known_uri_id, :integer
  end
end
