class CreateClassificationCurations < ActiveRecord::Migration

  def self.up

    create_table :classification_curations do |t|
      t.integer :exemplar_id
      t.integer :source_id, :null => false
      t.integer :target_id
      t.integer :user_id, :null => false
      t.boolean :forced
      t.string  :error, :limit => 256
      t.datetime :completed_at
      t.timestamps
    end
    
    create_table :hiearchy_entry_moves do |t|
      t.integer :hierarchy_entry_id, :null => false
      t.integer :classification_curation_id, :null => false
      t.string  :error, :limit => 256
      t.datetime :completed_at
    end

    execute 'CREATE UNIQUE INDEX hierarchy_entry_curation ON hiearchy_entry_moves(hierarchy_entry_id, classification_curation_id)'

    ChangeableObjectType.create(:ch_object_type => 'classification_curation')

  end

  def self.down
    drop_table :hiearchy_entry_moves
    drop_table :classification_curations
  end

end
