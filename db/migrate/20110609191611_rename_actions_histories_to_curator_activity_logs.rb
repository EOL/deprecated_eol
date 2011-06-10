class RenameActionsHistoriesToCuratorActivityLogs < ActiveRecord::Migration
  def self.up
    rename_table :actions_histories, :curator_activity_logs
  end

  def self.down
    rename_table :curator_activity_logs, :actions_histories
  end
end
