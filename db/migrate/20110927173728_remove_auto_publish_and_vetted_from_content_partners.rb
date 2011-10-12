class RemoveAutoPublishAndVettedFromContentPartners < ActiveRecord::Migration
  def self.up
    execute('UPDATE resources r JOIN content_partners cp ON cp.id = r.content_partner_id SET r.auto_publish = cp.auto_publish WHERE cp.auto_publish = 1')
    execute('UPDATE resources r JOIN content_partners cp ON cp.id = r.content_partner_id SET r.vetted = cp.vetted WHERE cp.vetted = 1')
    remove_column :content_partners, :auto_publish
    remove_column :content_partners, :vetted
  end

  def self.down
    add_column :content_partners, :auto_publish, :boolean, :default => 0, :null => false
    add_column :content_partners, :vetted, :boolean, :default => 0, :null => false
  end
end
