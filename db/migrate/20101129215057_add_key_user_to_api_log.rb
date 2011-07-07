class AddKeyUserToApiLog < EOL::LoggingMigration
  def self.up
    # execute "ALTER TABLE `api_logs` ADD COLUMN `key` CHAR(40) AFTER `format`"
    # execute "ALTER TABLE `api_logs` ADD COLUMN `user_id` INT AFTER `key`"
  end

  def self.down
    remove_column :api_logs, :user_id
    remove_column :api_logs, :key
  end
end
