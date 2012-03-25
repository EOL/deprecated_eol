class ChangeGoogleAnalyticsIndices < ActiveRecord::Migration
  def self.up
    execute "DROP INDEX taxon_concept_id ON google_analytics_partner_taxa"
    execute "DROP INDEX user_id ON google_analytics_partner_taxa"

    execute "DROP INDEX taxon_concept_id ON google_analytics_page_stats"
    execute "DROP INDEX year ON google_analytics_page_stats"
    execute "DROP INDEX month ON google_analytics_page_stats"
    execute "DROP INDEX page_views ON google_analytics_page_stats"

    execute "CREATE INDEX concept_user_month_year ON google_analytics_partner_taxa(taxon_concept_id, user_id, month, year)"
    execute "CREATE INDEX month_year ON google_analytics_page_stats(month, year)"
  end

  def self.down
    execute "DROP INDEX concept_user_month_year ON google_analytics_partner_taxa"
    execute "DROP INDEX month_year ON google_analytics_page_stats"

    execute "CREATE INDEX taxon_concept_id ON google_analytics_partner_taxa(taxon_concept_id)"
    execute "CREATE INDEX user_id ON google_analytics_partner_taxa(user_id)"

    execute "CREATE INDEX taxon_concept_id ON google_analytics_page_stats(taxon_concept_id)"
    execute "CREATE INDEX year ON google_analytics_page_stats(year)"
    execute "CREATE INDEX month ON google_analytics_page_stats(month)"
    execute "CREATE INDEX page_views ON google_analytics_page_stats(page_views)"
  end
end
