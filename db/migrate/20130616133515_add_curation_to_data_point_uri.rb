class AddCurationToDataPointUri < ActiveRecord::Migration
  def change
    vet_default = Vetted.unknown.id rescue 1
    vis_default = Visibility.visible.id rescue 2
    add_column :data_point_uris, :vetted_id, :integer, :default => vet_default
    add_column :data_point_uris, :visibility_id, :integer, :default => vis_default
  end
end
