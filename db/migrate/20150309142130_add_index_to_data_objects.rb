class AddIndexToDataObjects < ActiveRecord::Migration
  def change
    add_index(:data_objects, [:guid, :language_id])
  end
end
