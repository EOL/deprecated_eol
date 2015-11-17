class AddHarvestableToResources < ActiveRecord::Migration
  def up
    add_column(:resources, :harvestable, :boolean, default: true)
    # Sucks to have to add these, but these were HARD-CODED in PHP:
    Resource.where(id: [77, 710, 752]).update_all(harvestable: true)
  end

  def down
    remove_column(:resources, :harvestable)
  end
end
