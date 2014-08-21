class ContentPartnerPublicToIsPublic < ActiveRecord::Migration
  def change
    rename_column :content_partners, :public, :is_public
  end
end
