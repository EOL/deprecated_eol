class CreateUserRecordsInAgents < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    SpeciesSchemaModel.connection.begin_db_transaction
    
    all_users = User.find_by_sql("SELECT * FROM users")
    all_users.each do |u|
      full_name = u.given_name || ""
      full_name += " " + u.family_name unless u.family_name.blank?
      
      agent_id = SpeciesSchemaModel.connection.insert(ActiveRecord::Base.eol_escape_sql ["insert into agents (full_name, created_at, updated_at) values (?, now(), now())", full_name])
      SpeciesSchemaModel.connection.execute("UPDATE #{User.full_table_name} SET agent_id=#{agent_id} WHERE id=#{u.id}")
    end
    
    SpeciesSchemaModel.connection.commit_db_transaction
  end

  def self.down
    agent_ids = User.all.map {|u| u.agent_id}
    execute "delete from agents where id in (#{agent_ids.join(',')})" if !agent_ids.empty?
  end
end
