class AddLoggingEmailFieldsContacts < EOL::DataMigration
  def self.up
    add_column :agent_contacts, :email_reports_frequency_hours, :integer, :default => 24
    add_column :agent_contacts, :last_report_email, :timestamp
    
  end

  def self.down
    remove_column :agent_contacts, :email_reports_frequency_hours
    remove_column :agent_contacts, :last_report_email
  end
end
