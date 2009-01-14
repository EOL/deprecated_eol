class UpdateContentPartnerAgreementAgain < ActiveRecord::Migration
  def self.database_model
     return "SpeciesSchemaModel"
   end

   def self.up
     change_table :content_partner_agreements do |t|
       t.string :ip_address
       t.datetime :signed_on_date
       t.string :signed_by
     end
   end

   def self.down
     remove_column :content_partner_agreements,:ip_address
     remove_column :content_partner_agreements,:signed_on_date
     remove_column :content_partner_agreements,:signed_by     
   end
end
