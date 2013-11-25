class CreateUriTypes < ActiveRecord::Migration

  def up
    create_table :uri_types do |t|
     # Really nothing to do here.  :\  It's just an ID!
    end
    create_table :translated_uri_types do |t|
      t.string :name, limit: 32
      t.integer :uri_type_id, null: false
      t.integer :language_id, null: false
    end
    UriType.create_defaults
    add_column :known_uris, :uri_type_id, :integer, null: false, default: UriType.measurement.id
    KnownUri.where(:is_unit_of_measure => true).each do |uri|
      uri.update_attributes(:uri_type => UriType.value)
    end
    remove_column :known_uris, :is_unit_of_measure
  end

  def down
    add_column :known_uris, :is_unit_of_measure, :boolean, default: false
    # cannot reliably undo the assignment of UriType.value to units of measure
    remove_column :known_uris, :uri_type_id
    drop_table :translated_uri_types
    drop_table :uri_types
  end

end
