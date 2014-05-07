class AddValueIsTextFlagToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :value_is_text, :boolean, :default => false
  end
end
