class CreateHierarchyReindexings < ActiveRecord::Migration
  def change
    create_table :hierarchy_reindexings do |t|
      t.references :hierarchy
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
