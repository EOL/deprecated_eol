class CuratorLogging < ActiveRecord::Migration

  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    create_table :curator_activities, :comment => "A largely static list of high-level activities performed by curators." do |t|
      t.string :code, :null => false
      t.timestamps :null => false
    end
    create_table :curator_comment_logs, :comment => "Raw data entries needing mining." do |t|      
      t.integer :user_id, :null => false
      t.integer :comment_id, :null => false
      t.timestamps :null => false
    end
    create_table :curator_data_object_logs, :comment => "Raw data entries needing mining." do |t|
      t.integer :user_id, :null => false
      t.integer :data_object_id, :null => false
      t.timestamps :null => false
    end
    create_table :curator_activity_log_dailies, :comment => "Mined data facts." do |t|      
      t.integer :user_id, :null => false
      t.integer :comments_updated, :null => false, :default => 0
      t.integer :comments_deleted, :null => false, :default => 0
      t.integer :data_objects_updated, :null => false, :default => 0
      t.integer :data_objects_deleted, :null => false, :default => 0
      t.integer :year, :null => false
      t.integer :date, :null => false
      t.timestamps :null => false
    end
  end

  def self.down
    drop_table :curator_activity_log_dailies
    drop_table :curator_data_object_logs
    drop_table :curator_comment_logs
    drop_table :curator_activities
  end

end
