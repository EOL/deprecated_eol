class AddUserApiKey < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `users` ADD COLUMN `api_key` CHAR(40)"
    add_index :users, [:api_key], :name => 'index_users_on_api_key'
  end

  def self.down
    remove_column :users, :api_key
  end
end
