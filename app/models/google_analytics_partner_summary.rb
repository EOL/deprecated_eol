class GoogleAnalyticsPartnerSummary < SpeciesSchemaModel
  belongs_to :agent
  set_primary_keys :year, :month, :agent_id
  
  
  def self.summary(agent_id, report_year, report_month)
    query = "Select 
    google_analytics_partner_summaries.taxa_pages,
    google_analytics_partner_summaries.taxa_pages_viewed,
    google_analytics_partner_summaries.unique_page_views,
    google_analytics_partner_summaries.page_views,
    format(google_analytics_partner_summaries.time_on_page/60/60,2) `timeonpage`,
    google_analytics_summaries.pageviews,
    google_analytics_summaries.unique_pageviews,
    google_analytics_summaries.taxa_pages eol_taxa_pages,
    google_analytics_summaries.taxa_pages_viewed eol_taxa_pages_viewed,
    format(google_analytics_summaries.time_on_pages/60/60,0) `timeonpages`
    From google_analytics_partner_summaries
    Inner Join google_analytics_summaries ON 
    google_analytics_partner_summaries.`year` = google_analytics_summaries.`year` AND 
    google_analytics_partner_summaries.`month` = google_analytics_summaries.`month`
    Where
    google_analytics_partner_summaries.agent_id = ? AND
    google_analytics_partner_summaries.`year` = ? AND
    google_analytics_partner_summaries.`month` = ?"
    
    self.find_by_sql [query, agent_id, report_year, report_month]    
  end
  
end
class GoogleAnalyticsPartnerSummary < SpeciesSchemaModel
  belongs_to :agent
  set_primary_keys :year, :month, :agent_id
  
  
  def self.summary(agent_id, report_year, report_month)
    query = "Select 
    google_analytics_partner_summaries.taxa_pages,
    google_analytics_partner_summaries.taxa_pages_viewed,
    google_analytics_partner_summaries.unique_page_views,
    google_analytics_partner_summaries.page_views,
    format(google_analytics_partner_summaries.time_on_page/60/60,2) `timeonpage`,
    google_analytics_summaries.pageviews,
    google_analytics_summaries.unique_pageviews,
    google_analytics_summaries.taxa_pages eol_taxa_pages,
    google_analytics_summaries.taxa_pages_viewed eol_taxa_pages_viewed,
    format(google_analytics_summaries.time_on_pages/60/60,0) `timeonpages`
    From google_analytics_partner_summaries
    Inner Join google_analytics_summaries ON 
    google_analytics_partner_summaries.`year` = google_analytics_summaries.`year` AND 
    google_analytics_partner_summaries.`month` = google_analytics_summaries.`month`
    Where
    google_analytics_partner_summaries.agent_id = ? AND
    google_analytics_partner_summaries.`year` = ? AND
    google_analytics_partner_summaries.`month` = ?"
    
    self.find_by_sql [query, agent_id, report_year, report_month]    
  end
  
end