class AddValueIsVerbatimFlagToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :value_is_verbatim, :boolean, :default => false
  end
end
