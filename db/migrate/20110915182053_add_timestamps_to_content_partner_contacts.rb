class AddTimestampsToContentPartnerContacts < ActiveRecord::Migration
  def self.up
    add_timestamps :content_partner_contacts
  end

  def self.down
    remove_timestamps :content_partner_contacts
  end
end
