class AddHideFromGuiToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :hide_from_gui, :boolean, :default => false
  end
end
