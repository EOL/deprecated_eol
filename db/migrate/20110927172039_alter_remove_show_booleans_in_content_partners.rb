class AlterRemoveShowBooleansInContentPartners < ActiveRecord::Migration
  def self.up
    remove_column :content_partners, :show_mou_on_partner_page
    remove_column :content_partners, :show_gallery_on_partner_page
    remove_column :content_partners, :show_stats_on_partner_page
    rename_column :content_partners, :show_on_partner_page, :public
  end

  def self.down
    add_column :content_partners, :show_mou_on_partner_page, :boolean, :default => 0, :null => false
    add_column :content_partners, :show_gallery_on_partner_page, :boolean, :default => 0, :null => false
    add_column :content_partners, :show_stats_on_partner_page, :boolean, :default => 0, :null => false
    rename_column :content_partners, :public, :show_on_partner_page
  end
end
