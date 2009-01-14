class CreateErrorLogs < ActiveRecord::Migration
  def self.up
    create_table :error_logs do |t|
      t.column :exception_name, :string, :limit=>250
      t.column :backtrace, :text
      t.column :url, :string, :limit=>250
      t.column :user_id, :integer
      t.column :user_agent, :string, :limit=>100
      t.column :ip_address, :string
      t.timestamps 
    end
  end

  def self.down
    drop_table :error_logs
  end
end
