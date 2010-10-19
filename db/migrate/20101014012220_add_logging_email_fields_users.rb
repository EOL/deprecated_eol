class AddLoggingEmailFieldsUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_reports_frequency_hours, :integer, :default => 24
    add_column :users, :last_report_email, :timestamp
    
  end

  def self.down
    remove_column :users, :email_reports_frequency_hours
    remove_column :users, :last_report_email
  end
end
