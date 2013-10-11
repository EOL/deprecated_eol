class AddDescriptionToKnownUris < ActiveRecord::Migration
  def up
    remove_column :known_uris, :description
    add_column :translated_known_uris, :definition, :text
    add_column :translated_known_uris, :comment, :text
  end

  def down
    add_column :known_uris, :description, :text
    remove_column :translated_known_uris, :definition
    remove_column :translated_known_uris, :comment
  end
end
