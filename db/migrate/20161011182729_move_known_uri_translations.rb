class MoveKnownUriTranslations < ActiveRecord::Migration
  def up
    # add_column :known_uris, :name, :string, default: "Unknown!", limit: 128
    # add_column :known_uris, :definition, :text
    # add_column :known_uris, :comment, :text
    # add_column :known_uris, :attribution, :text
    TranslatedKnownUri.where(language_id: 152).find_each do |tku|
      next unless tku.known_uri
      tku.known_uri.update_attributes(
        name: tku.name,
        definition: tku.definition,
        comment: tku.comment,
        attribution: tku.attribution
      )
    end
    change_column :known_uris, :name, :string, null: false, limit: 128
  end

  def down
    remove_column :known_uris, :name
    remove_column :known_uris, :definition
    remove_column :known_uris, :comment
    remove_column :known_uris, :attribution
  end
end
