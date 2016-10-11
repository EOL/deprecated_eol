class MoveKnownUriTranslations < ActiveRecord::Migration
  def up
    add_column :known_uris, :name, :string, default: "Unknown!", limit: 128
    add_column :known_uris, :description, :text
    add_column :known_uris, :comment, :text
    add_column :known_uris, :attribution, :text
    TranslatedKnownUri.where(language_id: 152).find_each do |tku|
      tku.known_uri.update_attributes(
        name: tku.name,
        description: tku.description,
        comment: tku.comment,
        attribution: tku.attribution
      )
    end
    change_column :known_uris, :name, :string, null: false, limit: 128
  end

  def down
    remove_column :known_uris, :name
    remove_column :known_uris, :description
    remove_column :known_uris, :comment
    remove_column :known_uris, :attribution
  end
end
