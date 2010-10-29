class AddLoggingFieldToAgents < EOL::DataMigration
  def self.up
    add_column :agents, :email_reports_frequency_hours, :integer, :default => 24
    add_column :agents, :last_report_email, :timestamp
    
  end

  def self.down
    remove_column :agents, :email_reports_frequency_hours
    remove_column :agents, :last_report_email
  end
end
