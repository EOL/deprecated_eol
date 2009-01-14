class UpdateAgentsResourcesRelationship < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    remove_column :resources,:agent_id
  end

  def self.down
    add_column :resources,:agent_id,:integer
  end

end
