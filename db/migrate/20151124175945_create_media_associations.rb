# 20151124175945
class CreateMediaAssociations < ActiveRecord::Migration
  def up
    create_table :media_associations do |t|
      t.integer :hierarchy_entry_id, null: false
      t.integer :data_object_id, null: false
      # NOTE: this is not a float, like it usual is! I'm minimizing size.
      t.integer :rating, null: false, default: 250
      t.integer :vet_sort, null: false, default: 1, :limit => 2
      t.boolean :visible, null: false, default: true
      t.boolean :preview, null: false, default: false
      t.boolean :published, null: false, default: true
    end
    add_index :media_associations, [:hierarchy_entry_id]
  end

  def down
    drop_table :media_associations
  end
end
