class MoveVettedFromDatoToDohe < ActiveRecord::Migration
  def self.up
    vetted_id = Vetted.trusted.id rescue nil
    add_column :data_objects_hierarchy_entries, :vetted_id, :integer, :null => true
    add_column :data_objects_hierarchy_entries, :visibility_id, :integer, :null => true
    options = {:null => false}
    options[:default] = vetted_id if vetted_id
    add_column :curated_data_objects_hierarchy_entries, :vetted_id, :integer, options
    add_column :curated_data_objects_hierarchy_entries, :visibility_id, :integer, :null => true
    DataObjectsHierarchyEntry.connection.execute("
      UPDATE data_objects_hierarchy_entries dohe, data_objects dato SET dohe.vetted_id = dato.vetted_id, dohe.visibility_id = dato.visibility_id WHERE dohe.data_object_id = dato.id
    ")
    DataObjectsHierarchyEntry.connection.execute("
      ALTER TABLE data_objects_hierarchy_entries MODIFY vetted_id INT NOT NULL
    ")
  end

  def self.down
    remove_column :data_objects_hierarchy_entries, :visibility_id rescue nil
    remove_column :data_objects_hierarchy_entries, :vetted_id rescue nil
    remove_column :curated_data_objects_hierarchy_entries, :visibility_id rescue nil
    remove_column :curated_data_objects_hierarchy_entries, :vetted_id rescue nil
  end
end
