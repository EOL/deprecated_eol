class AddOverwriteToCollectionJobs < ActiveRecord::Migration
  def change
    add_column :collection_jobs, :overwrite, :boolean, :default => false
  end
end
