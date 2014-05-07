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
    
    create_table :hierarchy_entry_moves do |t|
      t.integer :hierarchy_entry_id, :null => false
      t.integer :classification_curation_id, :null => false
      t.string  :error, :limit => 256
      t.datetime :completed_at
    end

    add_index :hierarchy_entry_moves, [:hierarchy_entry_id, :classification_curation_id], :unique => true,
      :name => 'entry_and_curation_index'
    add_index :hierarchy_entry_moves, :hierarchy_entry_id

    ChangeableObjectType.create(:ch_object_type => 'classification_curation')
    Activity.create_enumerated

  end

  def self.down
    drop_table :hierarchy_entry_moves
    drop_table :classification_curations
  end

end
