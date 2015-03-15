class AddFileNumberToDataSearchFiles < ActiveRecord::Migration
  def change
    add_column :data_search_files, :file_number, :integer
  end
end
