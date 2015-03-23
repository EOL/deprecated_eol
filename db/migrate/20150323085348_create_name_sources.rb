class CreateNameSources < ActiveRecord::Migration
  def change
    create_table :name_sources do |t|
      t.integer :common_name_id
      t.string :name
      t.string :source_type, null: false
      t.integer :source_id, null: false
      t.integer :content_partner_id # only used when the source is a Resrouce
      t.timestamps
    end
    add_index :name_sources, :common_name_id
  end
end
