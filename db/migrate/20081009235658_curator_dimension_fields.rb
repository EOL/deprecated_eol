class CuratorDimensionFields < ActiveRecord::Migration
  
  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    add_column :curator_data_object_logs, :curator_activity_id, :integer, :null => false
    add_column :curator_comment_logs, :curator_activity_id, :integer, :null => false
  end
  
  def self.down
    remove_column :curator_data_object_logs, :curator_activity_id
    remove_column :curator_comment_logs, :curator_activity_id
  end
  
end
