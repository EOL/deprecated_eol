class AddSearchTypeToLogs < ActiveRecord::Migration
  
  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    add_column :search_logs,:search_type, :string,:null=>true, :default=>'text'
  end

  def self.down
    remove_column :search_logs, :search_type
  end
  
end
