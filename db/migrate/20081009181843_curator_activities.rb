class CuratorActivities < ActiveRecord::Migration
  
  def self.up
    %w(delete update).each do |code|
      LoggingModel.connection.execute("INSERT INTO curator_activities(`code`) VALUES('#{code}')")
    end
  end
  
  def self.down
    LoggingModel.connection.execute("DELETE FROM curator_activities")    
  end
  
end
