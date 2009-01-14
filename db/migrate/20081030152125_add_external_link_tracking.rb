class AddExternalLinkTracking < ActiveRecord::Migration
  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    create_table :external_link_logs, :force => true, :comment => 'The log table for tracking external links.' do |t|
      t.string :external_url, :null => false
      t.integer :ip_address_raw, :null => false, :comment => 'Integer-encoded IP address.'
      t.integer :ip_address_id, :null => true
      t.integer :user_id, :null => true
      t.string :user_agent, :null => false, :limit => 160, :comment => 'Ex: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1'
      t.string :path, :null => true, :limit => 128, :comment => 'Ex: /content/index?welcome=true'
      t.timestamps
    end
  end

  def self.down
    drop_table :external_link_logs
  end
end
