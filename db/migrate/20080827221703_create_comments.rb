class CreateComments < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end 

  def self.up
    create_table :comments do |t|
      t.references :user
      t.references :data_object
      t.text       :body
      t.datetime   :visible_at
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end

end
