class UpdateContentPartnerModel < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    add_column :content_partners,:show_on_partner_page, :boolean,:null=>false, :default=>false
    add_column :resources,:vetted, :boolean, :null=>false, :default=>false    
    rename_column :content_partners, :partner_vetted, :vetted    
  end

  def self.down
    remove_column :content_partners, :show_on_partner_page
    remove_column :resources, :vetted
    rename_column :content_partners, :vetted, :partner_vetted    
  end
end
