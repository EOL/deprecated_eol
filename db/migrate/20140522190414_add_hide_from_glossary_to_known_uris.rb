class AddHideFromGlossaryToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :hide_from_glossary, :boolean, :default => false
  end
end
