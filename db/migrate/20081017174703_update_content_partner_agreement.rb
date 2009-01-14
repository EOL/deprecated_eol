class UpdateContentPartnerAgreement < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    add_column :content_partner_agreements,:mou_url, :string,:null=>true
  end

  def self.down
    remove_column :content_partner_agreements,:mou_url
  end
end
