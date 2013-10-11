class CreateDataPointUris < ActiveRecord::Migration
  def change
    create_table :data_point_uris do |t|
      t.string :uri, length: 128 # Limit so that it's searchable.  :\
      t.integer :taxon_concept_id
      t.timestamps
    end
    add_index :data_point_uris, [:uri, :taxon_concept_id]
  end
end
