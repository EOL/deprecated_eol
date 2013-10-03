class AddSourceToTranslatedKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :ontology_information_url, :string
    add_column :known_uris, :ontology_source_url, :string
    add_column :translated_known_uris, :attribution, :text
  end
end
