class RemoveStepsColumnsFromContentPartners < ActiveRecord::Migration
  def self.up
    remove_column :content_partners, :partner_seen_step
    remove_column :content_partners, :partner_complete_step
    remove_column :content_partners, :contacts_seen_step
    remove_column :content_partners, :contacts_complete_step
    remove_column :content_partners, :licensing_seen_step
    remove_column :content_partners, :licensing_complete_step
    remove_column :content_partners, :attribution_seen_step
    remove_column :content_partners, :attribution_complete_step
    remove_column :content_partners, :roles_seen_step
    remove_column :content_partners, :roles_complete_step
    remove_column :content_partners, :transfer_overview_seen_step
    remove_column :content_partners, :transfer_overview_complete_step
    remove_column :content_partners, :transfer_upload_seen_step
    remove_column :content_partners, :transfer_upload_complete_step
    remove_column :content_partners, :specialist_overview_seen_step
    remove_column :content_partners, :specialist_overview_complete_step
    remove_column :content_partners, :specialist_formatting_seen_step
    remove_column :content_partners, :specialist_formatting_complete_step
    remove_column :content_partners, :last_completed_step
    remove_column :content_partners, :ipr_accept
    remove_column :content_partners, :attribution_accept
    remove_column :content_partners, :roles_accept
    remove_column :content_partners, :transfer_schema_accept
    remove_column :content_partners, :eol_notified_of_acceptance
  end

  def self.down
    change_table(:content_partners) do |t|
      t.boolean   :ipr_accept, :attribution_accept, :roles_accept, :transfer_schema_accept,
                  :null => false, :default => 0
      t.datetime  :eol_notified_of_acceptance, :null => true, :default => nil
      t.string    :last_completed_step, :limit => 40, :null => true, :default => nil
    end
    %w(partner_seen_step partner_complete_step contacts_seen_step contacts_complete_step
       licensing_seen_step licensing_complete_step attribution_seen_step attribution_complete_step
       roles_seen_step roles_complete_step transfer_overview_seen_step transfer_overview_complete_step
       transfer_upload_seen_step transfer_upload_complete_step
       specialist_overview_seen_step specialist_overview_complete_step
       specialist_formatting_seen_step specialist_formatting_complete_step).each do |column_name|
      execute("ALTER TABLE `content_partners` ADD `#{column_name}` timestamp NULL DEFAULT NULL")
    end
  end
end
