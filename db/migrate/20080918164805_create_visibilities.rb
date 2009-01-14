class CreateVisibilities < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    create_table :visibilities do |t|
      t.string :label
      t.timestamps # This is a tiny table; I don't really foresee a need for them, but hey!
    end
    Visibility.create(:label => 'Visible')
    Visibility.create(:label => 'Preview')
    Visibility.create(:label => 'Inappropriate')
    add_column :data_objects, :visibility_id, :integer
    DataObject.all.each do |dato|
      dato.visibility_id = dato.visible
      dato.save
    end
    remove_column :data_objects, :visible
  end

  def self.down
    drop_table :visibilities
    add_column :data_objects, :visible, :integer
    DataObject.all.each do |dato|
      dato.visible = dato.visibility_id == 1 ? 1 : 0
      dato.save
    end
    remove_column :data_objects, :visibility_id
  end
end
