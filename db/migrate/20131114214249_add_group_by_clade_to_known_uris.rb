class AddGroupByCladeToKnownUris < ActiveRecord::Migration
  def change
    add_column :known_uris, :group_by_clade, :boolean
    add_column :known_uris, :clade_exemplar, :boolean
  end
end
