class AddLastHarvestSecondsToResources < ActiveRecord::Migration
  def change
    add_column :resources, :last_harvest_seconds, :integer
  end
end
