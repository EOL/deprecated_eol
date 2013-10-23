class AddFileUrlsToDataSearchFiles < ActiveRecord::Migration
  def change
    add_column :data_search_files, :hosted_file_url, :string
  end
end
