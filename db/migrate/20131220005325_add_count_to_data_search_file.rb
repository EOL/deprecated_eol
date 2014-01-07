class AddCountToDataSearchFile < ActiveRecord::Migration
  def change
    add_column :data_search_files, :row_count, 'integer unsigned'
  end
end
