class CreateCollectionDownloadFiles < ActiveRecord::Migration
  def change
    create_table :collection_download_files do |t|
      t.integer :user_id
      t.integer :collection_id
      t.integer :file_number
      t.integer :row_count
      t.string :error
      t.string :hosted_file_url
      t.datetime :failed_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
