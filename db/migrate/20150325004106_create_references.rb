class CreateReferences < ActiveRecord::Migration
  def change
    create_table :references do |t|
      t.integer :parent_id
      t.string :parent_type
      t.string :body
    end
  end
end
