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
  end

  def down
    drop_table :uri_types
    drop_table :translated_uri_types
    remove_column :known_uris, :uri_type_id
  end

end
