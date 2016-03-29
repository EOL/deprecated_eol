class CreatePageFeatures < ActiveRecord::Migration
  def change
    create_table :page_features do |t|
      t.boolean :map_json, default: false
    end
  end
end
