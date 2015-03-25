class CreateCredits < ActiveRecord::Migration
  def change
    create_table :credits do |t|
      t.string :credited_for_type
      t.integer :credited_for_id
      t.string :name
      t.string :role
      t.string :url
      t.timestamps
    end
    add_index :credits, [:credited_for_id, :credited_for_type],
      name: "credited_for"
  end
end
