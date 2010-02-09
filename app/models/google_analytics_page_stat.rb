class GoogleAnalyticsPageStat < SpeciesSchemaModel
  belongs_to :taxon_concept
  set_primary_keys :taxon_concept_id, :year, :month, :page_views
  
  
  def self.page_summary(agent_id, year, month, page)
    query="
Select names.`string` scientific_name,
google_analytics_page_stats.taxon_concept_id,
google_analytics_page_stats.page_views,
google_analytics_page_stats.unique_page_views,
time_to_sec(google_analytics_page_stats.time_on_page) `timeonpage`
From
google_analytics_page_stats
Join google_analytics_partner_taxa ON google_analytics_page_stats.taxon_concept_id = google_analytics_partner_taxa.taxon_concept_id
Join taxon_concepts ON taxon_concepts.id = google_analytics_page_stats.taxon_concept_id
Join taxon_concept_names ON taxon_concepts.id = taxon_concept_names.taxon_concept_id
Join names ON taxon_concept_names.name_id = names.id

      Where google_analytics_partner_taxa.agent_id = ? AND
      google_analytics_partner_taxa.`year` = ? AND
      google_analytics_partner_taxa.`month` = ?


group by google_analytics_page_stats.taxon_concept_id
order by google_analytics_page_stats.page_views desc"
      
      
    self.paginate_by_sql [query, agent_id, year, month], :page => page, :per_page => 50 , :order => 'page_views'
    
    
    
    
   end
end
