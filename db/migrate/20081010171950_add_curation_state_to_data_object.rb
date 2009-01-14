class AddCurationStateToDataObject < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    change_table :data_objects do |t|
      t.boolean :curated, :null=>false, :default=>false
    end
    rename_column :data_objects,:vetted,:vetted_id
    create_table :vetted do |t|
      t.string :label, :default=>''
      t.timestamps
    end    
    trusted = Vetted.create(:label => 'Trusted')
    unknown = Vetted.create(:label => 'Unknown')
    untrusted = Vetted.create(:label => 'Untrusted')
    Vetted.connection.execute("UPDATE vetted SET id=0 WHERE id=#{untrusted.id}") # gotta get that ID to 0
  end

  def self.down
    remove_column :data_objects, :curated
    drop_table :vetted
  end
end
