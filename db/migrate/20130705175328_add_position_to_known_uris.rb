class AddPositionToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :position, :integer
  end
end
