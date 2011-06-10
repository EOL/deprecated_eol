class RenameActionsHistoriesUntrustReasonsToCuratorActivityLogsUntrustReasons < ActiveRecord::Migration
  def self.up
    rename_table :actions_histories_untrust_reasons, :curator_activity_logs_untrust_reasons
  end

  def self.down
    rename_table :curator_activity_logs_untrust_reasons, :actions_histories_untrust_reasons
  end
end
