class GoogleAnalyticsPageStat < SpeciesSchemaModel
  belongs_to :taxon_concept
  set_primary_keys :taxon_concept_id, :year, :month, :page_views
  
  
  def self.page_summary(agent_id, year, month, page)
    query="Select
      taxa.scientific_name,
      google_analytics_page_stats.taxon_concept_id,
      Sum(google_analytics_page_stats.page_views) page_views,
      Sum(google_analytics_page_stats.unique_page_views) unique_page_views,
      Sum(time_to_sec(google_analytics_page_stats.time_on_page)) `timeonpage`
      From google_analytics_page_stats
      Inner Join google_analytics_partner_taxa ON google_analytics_partner_taxa.taxon_concept_id = google_analytics_page_stats.taxon_concept_id AND google_analytics_partner_taxa.`year` = google_analytics_page_stats.`year` AND google_analytics_partner_taxa.`month` = google_analytics_page_stats.`month`
      Inner Join taxon_concept_names ON google_analytics_page_stats.taxon_concept_id = taxon_concept_names.taxon_concept_id
      Inner Join taxa ON taxon_concept_names.name_id = taxa.name_id
      Where google_analytics_partner_taxa.agent_id = ? AND
      google_analytics_partner_taxa.`year` = ? AND
      google_analytics_partner_taxa.`month` = ?
      Group By google_analytics_page_stats.taxon_concept_id
      Order By google_analytics_page_stats.page_views Desc"
    self.paginate_by_sql [query, agent_id, year, month], :page => page, :per_page => 100, :order => 'page_views'  
   end
end
