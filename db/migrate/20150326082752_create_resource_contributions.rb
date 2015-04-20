class CreateResourceContributions < ActiveRecord::Migration
  def change
    create_table :resource_contributions do |t|
      t.references :resource
      t.references :data_point_uri
      t.references :data_object
      t.references :hierarchy_entry
      t.references :taxon_concept
      t.string :source
      t.string :identifier
      t.string :object_type
      t.integer :data_object_type
      t.string :predicate
    end
    add_index :resource_contributions, :resource_id
  end
end