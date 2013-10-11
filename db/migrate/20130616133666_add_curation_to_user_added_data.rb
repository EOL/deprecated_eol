class AddCurationToUserAddedData < ActiveRecord::Migration
  def change
    vet_default = Vetted.unknown.id rescue 1
    vis_default = Visibility.visible.id rescue 2
    add_column :user_added_data, :vetted_id, :integer, :default => vet_default
    add_column :user_added_data, :visibility_id, :integer, :default => vis_default
  end
end
