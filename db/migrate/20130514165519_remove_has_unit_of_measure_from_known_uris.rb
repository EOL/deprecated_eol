class RemoveHasUnitOfMeasureFromKnownUris < ActiveRecord::Migration
  def self.up
    remove_column :known_uris, :has_unit_of_measure
  end

  def self.down
    add_column :known_uris, :has_unit_of_measure, :string, :after => :description
  end
end
