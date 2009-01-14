class UpdateContentPartner < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    rename_column :content_partners, :licenses_accept, :partner_vetted
    add_column :content_partners, :eol_notified_of_acceptance, :datetime, :null => true
    remove_column :content_partners, :active
  end

  def self.down
    rename_column :content_partners, :partner_vetted, :licenses_accept
    remove_column :content_partners, :eol_notified_of_acceptance
    add_column :content_partners, :active, :boolean, :null=>false, :default=>true
  end
  
end
