class AddLastViewedColumnToContentPartnerAgreement < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    add_column :content_partner_agreements,:last_viewed,:datetime
  end

  def self.down
    remove_column :content_partner_agreements,:last_viewed
  end
  
end
