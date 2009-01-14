class CreateContentPartnerAgreements < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    create_table :content_partner_agreements do |t|
      t.integer :agent_id, :null => false
      t.text :template, :null => false
      t.boolean :is_current, :default=>true, :null=>false
      t.integer :number_of_views, :default=>0, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :content_partner_agreements
  end
  
end
