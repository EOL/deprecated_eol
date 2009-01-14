class CreateSearchLog < ActiveRecord::Migration

  def self.database_model
    return "LoggingModel"
  end
  
  def self.up
    create_table :search_logs, :force => true, :comment => 'The search log table.' do |t|
      t.string :search_term
      t.integer :total_number_of_results
      t.integer :number_of_common_name_results
      t.integer :number_of_scientific_name_results
      t.integer :number_of_suggested_results                 
      t.integer :number_of_stub_page_results
      t.integer :ip_address_raw, :null => false, :comment => 'Integer-encoded IP address.'
      #t.integer :ip_address_id, :null => true removed it because it looks like duplication of information
      t.integer :user_id, :null => true
      t.integer :taxon_concept_id, :null => true
      t.integer :parent_search_log_id, :null=>true, :comment =>'Stores the id of a search that the user just ran, if they rerun another search immediatel'
      t.datetime :clicked_result_at, :null=>true
      t.string :user_agent, :null => false, :limit => 160, :comment => 'Ex: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1'
      t.string :path, :null => true, :limit => 128, :comment => 'Ex: /content/index?welcome=true'
      t.timestamps
    end
    add_index :search_logs, :search_term
  end

  def self.down
    drop_table :search_logs
  end
end
