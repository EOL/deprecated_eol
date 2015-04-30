class AddDataObjectTypeToResourceContributions < ActiveRecord::Migration
  def change
    add_column :resource_contributions, :data_object_type, :int
  end
end
