class ChangeCollectionJobToHaveManyTargets < ActiveRecord::Migration
  def up
    create_table :collections_collection_jobs do |t|
      t.integer :collection_id
      t.integer :collection_job_id
    end
    add_index :collections_collection_jobs, [:collection_id, :collection_job_id], :unique => true, :name => 'collections_collection_jobs_index'
    remove_column :collection_jobs, :target_collection_id
  end

  def down
    add_column :collection_jobs, :target_collection_id, :integer
    drop_table :collections_collection_jobs
  end
end
