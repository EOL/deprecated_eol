class AddSameAsExemplarToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :exemplar_for_same_as, :boolean
  end
end
