class AddFieldsToActionsHistories < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE actions_histories ADD comment_id int NULL AFTER action_with_object_id"
    execute "ALTER TABLE actions_histories ADD taxon_concept_id int NULL AFTER comment_id"
    
    execute "CREATE TABLE `actions_histories_untrust_reasons` (
      `actions_history_id` int(11) NOT NULL,
      `untrust_reason_id` int(11) NOT NULL,
      PRIMARY KEY (`actions_history_id`,`untrust_reason_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end

  def self.down
    remove_column :actions_histories, :comment_id
    remove_column :actions_histories, :taxon_concept_id
    drop_table :actions_histories_untrust_reasons
  end
end
