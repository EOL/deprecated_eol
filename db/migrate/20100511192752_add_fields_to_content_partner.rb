class AddFieldsToContentPartner < EOL::DataMigration
  
  def self.up
    execute('alter table content_partners add show_gallery_on_partner_page tinyint(1) NOT NULL default 0 after show_mou_on_partner_page')
    execute('alter table content_partners add show_stats_on_partner_page tinyint(1) NOT NULL default 0 after show_gallery_on_partner_page')
  end
  
  def self.down
    remove_column :content_partners, :show_gallery_on_partner_page
    remove_column :content_partners, :show_stats_on_partner_page
  end
end
