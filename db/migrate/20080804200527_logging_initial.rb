class LoggingInitial < ActiveRecord::Migration

  def self.database_model
    return "LoggingModel"
  end
 
   # Executes the given block for every fact table.
#  def self.daily_fact_tables(&block)
#    for dimension in ['data_object', 'agent', 'user', 'country', 'state'] do
#      {'daily' => 'day'}.each do |timeframe, unit|
#        name = "#{dimension}_log_#{timeframe.pluralize}"
#        yield(name, dimension, timeframe, unit) if block_given?
#      end      
#    end
#  end
  
  def self.up

    create_table :data_object_logs, :force => true, :comment => 'The master log table.' do |t|
      t.integer :data_object_id, :null => false
      t.integer :data_type_id, :null => false
      t.integer :ip_address_raw, :null => false, :comment => 'Integer-encoded IP address.'
      t.integer :ip_address_id, :null => true
      t.integer :user_id, :null => true
      t.integer :agent_id, :null => true
      t.string :user_agent, :null => false, :limit => 160, :comment => 'Ex: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1'
      t.string :path, :null => true, :limit => 128, :comment => 'Ex: /content/index?welcome=true'
      t.timestamps
    end
    
    create_table :ip_addresses, :comment => 'A cache of IP Address geocode lookups.' do |t|
      t.integer :number, :null => false
      t.boolean :success, :null => false
      t.string  :country_code, :null => true, :comment => 'ISO country code.'
      t.string  :city, :null => true
      t.string  :state, :null => true
      t.float :latitude, :null => true
      t.float :longitude, :null => true
      t.string  :provider, :null => false
      t.string  :street_address, :null => true
      t.string  :postal_code, :null => true
      t.string  :precision, :null => true
      t.timestamps
    end
    
    # A basic set of fact tables. These will evolve greatly over time.

    create_table :agent_log_dailies, :force => true do |t|
      t.integer :agent_id, :null => false
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.date    :day, :null => false
    end
    
    create_table :country_log_dailies, :force => true do |t|
      t.string :country_code, :null => true, :comment => 'Might not always be known.'
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.date    :day, :null => false
    end
    
    create_table :data_object_log_dailies, :force => true do |t|
      t.integer :data_object_id, :null => false
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.date    :day, :null => false
    end

    create_table :state_log_dailies, :force => true do |t|
      t.string  :state_code, :null => true, :comment => 'Might not always be known.'
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.date    :day, :null => false
    end
    
    create_table :user_log_dailies, :force => true do |t|
      t.integer :user_id, :null => false
      t.integer :data_type_id, :null => false
      t.integer :total, :null => false
      t.date    :day, :null => false
    end
    

    
    # Now create fact tables for all the information we're going to be mining...
#    daily_fact_tables do |name, dimension, timeframe, unit|
#      create_table name, :force => true do |t|
#        t.integer "#{dimension}_id", :null => false
#        t.integer unit, :null => false
#        t.integer :data_type_id, :null => false
#        t.integer :total, :null => false
#        t.date :day, :null => false
#      end
#    end
    
  end

  def self.down
#    daily_fact_tables do |name, dimension, timeframe, unit|
#      drop_table name
#    end

    drop_table :data_object_logs
    drop_table :ip_addresses
    
    drop_table :agent_log_dailies
    drop_table :country_log_dailies
    drop_table :data_object_log_dailies
    drop_table :state_log_dailies
    drop_table :user_log_dailies
  end

end
