class ChangeCollectionJobToHaveManyTargets < ActiveRecord::Migration
  def up
    create_table :collection_jobs_collections do |t|
      t.integer :collection_id
      t.integer :collection_job_id
    end
    add_index :collection_jobs_collections, [:collection_id, :collection_job_id], :unique => true, :name => 'collection_jobs_collections_index'
    remove_column :collection_jobs, :target_collection_id
  end

  def down
    add_column :collection_jobs, :target_collection_id, :integer
    drop_table :collection_jobs_collections
  end
end
