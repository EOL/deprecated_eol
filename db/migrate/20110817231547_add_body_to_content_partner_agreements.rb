class AddBodyToContentPartnerAgreements < ActiveRecord::Migration
  def self.up
    add_column :content_partner_agreements, :body, :text, :null => false
  end

  def self.down
    remove_column :content_partner_agreements, :body
  end
end
