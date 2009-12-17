class CreateUserRecordsInAgents < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    User.all.each do |user|
      agent_id = SpeciesSchemaModel.connection.insert(ActiveRecord::Base.eol_escape_sql ["insert into agents (full_name, created_at, updated_at) values (?, now(), now())", user.full_name])
      user.agent_id = agent_id
      user.save!
    end
  end

  def self.down
    agent_ids = User.all.map {|u| u.agent_id}
    execute "delete from agents where id in (#{agent_ids.join(',')})"
  end
end
