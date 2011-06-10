class RenameActionsHistoriesToCuratorActivityLogs < ActiveRecord::Migration
  def self.up
    rename_table :actions_histories, :curator_activity_logs
    rename_column :actions_histories_untrust_reasons, :actions_history_id, :curator_activity_log_id
  end

  def self.down
    rename_table :curator_activity_logs, :actions_histories rescue nil
    rename_column :actions_histories_untrust_reasons, :curator_activity_log_id, :actions_history_id rescue nil
  end
end
