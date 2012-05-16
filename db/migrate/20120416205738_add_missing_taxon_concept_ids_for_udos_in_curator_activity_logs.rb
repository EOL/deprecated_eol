class AddMissingTaxonConceptIdsForUdosInCuratorActivityLogs < ActiveRecord::Migration
  def self.up
    db_populated = begin
                     Activity.trusted
                     Activity.inappropriate
                   rescue
                     false
                   end
    if db_populated
      curator_action_ids = Activity.raw_curator_action_ids
      ch_object_type_id = ChangeableObjectType.users_data_object.id
      CuratorActivityLog.connection.execute "UPDATE `#{LoggingModel.database_name}`.`curator_activity_logs` cal join `#{ActiveRecord::Base.database_name}`.`users_data_objects` udo SET cal.taxon_concept_id = udo.taxon_concept_id WHERE cal.object_id = udo.data_object_id AND cal.changeable_object_type_id = #{ch_object_type_id} AND cal.activity_id IN (#{curator_action_ids.join(',')})"
    else
      puts "!! WARNING: This is not a failure, but the database didn't have a 'trusted' activity,"
      puts "   so I couldn't run this migration for real. This may be normal, but you should make sure."
    end
  end

  def self.down
    db_populated = begin
                     Activity.trusted
                     Activity.inappropriate
                   rescue
                     false
                   end
    if db_populated
      curator_action_ids = Activity.raw_curator_action_ids
      ch_object_type_id = ChangeableObjectType.users_data_object.id
      CuratorActivityLog.connection.execute "UPDATE `#{LoggingModel.database_name}`.`curator_activity_logs` cal SET cal.taxon_concept_id = NULL WHERE cal.changeable_object_type_id = #{ch_object_type_id} AND cal.activity_id IN (#{curator_action_ids.join(',')})"
    else
      puts "!! WARNING: This is not a failure, but the database didn't have a 'trusted' activity,"
      puts "   so I couldn't run this migration for real."
    end
  end
end
