class CreateIndicesForGoogleStats < ActiveRecord::Migration
  def self.up
    execute('create index taxon_concept_id on google_analytics_page_stats(taxon_concept_id)')
    execute('create index user_month on google_analytics_partner_taxa(user_id, month)')
  end

  def self.down
    remove_index :google_analytics_page_stats, :taxon_concept_id
    remove_index :google_analytics_partner_taxa, :user_month
  end
end
