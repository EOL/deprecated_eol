class CreateTableCollectionFromListStrings < ActiveRecord::Migration
  def up
    create_table :collection_from_list_strings do |t|
      t.integer :collection_from_list_id
      t.string :string
      t.boolean :exact, default: false
      t.boolean :unmatched, default: true
      t.timestamps
    end
  end

  def down
    drop_table :collection_from_list_strings
  end
end
