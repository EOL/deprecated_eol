class AddDataObjectGuidToCuratorActivityLogs < EOL::LoggingMigration
  def self.up
    add_column :curator_activity_logs, :data_object_guid, :string, :limit => 32
    execute "UPDATE `#{LoggingModel.database_name}`.curator_activity_logs cal join `#{ActiveRecord::Base.database_name}`.data_objects do SET cal.data_object_guid=do.guid WHERE cal.object_id=do.id AND cal.created_at > '2011-09-01 00:00:00' AND cal.changeable_object_type_id IN (#{ChangeableObjectType.data_object_scope.join(",")})"
  end

  def self.down
    remove_column :curator_activity_logs, :data_object_guid
  end
end
