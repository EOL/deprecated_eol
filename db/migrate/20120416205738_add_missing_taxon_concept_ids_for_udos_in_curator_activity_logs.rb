class AddMissingTaxonConceptIdsForUdosInCuratorActivityLogs < ActiveRecord::Migration
  def self.up
    curator_action_ids = Activity.raw_curator_action_ids
    ch_object_type_id = ChangeableObjectType.users_data_object.id
    CuratorActivityLog.connection.execute "UPDATE `#{LoggingModel.database_name}`.`curator_activity_logs` cal join `#{ActiveRecord::Base.database_name}`.`users_data_objects` udo SET cal.taxon_concept_id = udo.taxon_concept_id WHERE cal.object_id = udo.data_object_id AND cal.changeable_object_type_id = #{ch_object_type_id} AND cal.activity_id IN (#{curator_action_ids.join(',')})"
  end

  def self.down
    curator_action_ids = Activity.raw_curator_action_ids
    ch_object_type_id = ChangeableObjectType.users_data_object.id
    CuratorActivityLog.connection.execute "UPDATE `#{LoggingModel.database_name}`.`curator_activity_logs` cal SET cal.taxon_concept_id = NULL WHERE cal.changeable_object_type_id = #{ch_object_type_id} AND cal.activity_id IN (#{curator_action_ids.join(',')})"
  end
end