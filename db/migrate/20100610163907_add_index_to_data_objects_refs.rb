class AddIndexToDataObjectsRefs < EOL::DataMigration
  def self.up
    execute('create index do_id_ref_id on data_objects_refs(data_object_id, ref_id)')
  end

  def self.down
    remove_index :data_objects_refs, :name => 'do_id_ref_id'
  end
end
