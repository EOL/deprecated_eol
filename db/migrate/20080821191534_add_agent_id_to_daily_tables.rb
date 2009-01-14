class AddAgentIdToDailyTables < ActiveRecord::Migration

  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    %w( country data_object state user ).each do |t|
      add_column "#{t}_log_dailies".to_sym, :agent_id, :integer, :null => false
    end
  end

  def self.down
    %w( country data_object state user ).each do |t|
      remove_column "#{t}_log_dailies".to_sym, :agent_id
    end
  end

end
