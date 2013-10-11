class AddFieldsToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :description, :text
    add_column :known_uris, :has_unit_of_measure, :string, :limit => 2000
    add_column :known_uris, :is_unit_of_measure, :boolean, :default => false
  end
end
