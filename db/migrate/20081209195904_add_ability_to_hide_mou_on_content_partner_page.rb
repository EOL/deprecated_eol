class AddAbilityToHideMouOnContentPartnerPage < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    add_column :content_partners,:show_mou_on_partner_page, :boolean,:null=>false, :default=>false
  end

  def self.down
    remove_column :content_partners, :show_mou_on_partner_page
  end
end
