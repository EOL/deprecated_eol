class CreateCommonNames < ActiveRecord::Migration
  def change
    create_table :common_names do |t|
      t.integer :taxon_concept_id
      t.string :name
      t.string :language, limit: 8
      t.boolean :trusted
      t.boolean :preferred
      t.timestamps
    end
    add_index(:common_names, [:taxon_concept_id, :name, :language], unique: true, name: "by_tcn")
  end
end
