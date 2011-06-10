class RemoveDataObjectUntrustReason < ActiveRecord::Migration
  def self.up
    drop_table :data_objects_untrust_reasons
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new('Data Objects Untrust Reasons table was dropped and cannot be restored.')
  end
end
