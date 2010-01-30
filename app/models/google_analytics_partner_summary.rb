class GoogleAnalyticsPartnerSummary < SpeciesSchemaModel
  belongs_to :agent
  set_primary_keys :year, :month, :agent_id
  
  
  def self.summary(agent_id, report_year, report_month)
    query = "Select 
    format(google_analytics_partner_summaries.taxa_pages,0) taxa_pages,
    format(google_analytics_partner_summaries.taxa_pages_viewed,0) taxa_pages_viewed,
    format(google_analytics_partner_summaries.unique_page_views,0) unique_page_views,   
    google_analytics_partner_summaries.page_views,
    format(google_analytics_partner_summaries.time_on_page/60/60,2) `timeonpage`,
    
    format(google_analytics_summaries.taxa_pages,0) eol_taxa_pages,
    format(google_analytics_summaries.taxa_pages_viewed,0) eol_taxa_pages_viewed,  
    format(google_analytics_summaries.unique_pageviews,0) as unique_pageviews,
    google_analytics_summaries.pageviews,
    format(google_analytics_summaries.time_on_pages/60/60,0) `timeonpages`
    
    ,format(google_analytics_partner_summaries.taxa_pages/google_analytics_summaries.taxa_pages * 100,2)             as p_taxa_pages
    ,format(google_analytics_partner_summaries.taxa_pages_viewed/google_analytics_summaries.taxa_pages_viewed*100,2) as p_taxa_pages_viewed
    ,format(google_analytics_partner_summaries.unique_page_views/google_analytics_summaries.unique_pageviews*100,2)  as p_unique_page_views
    ,format(google_analytics_partner_summaries.page_views/google_analytics_summaries.pageviews*100,2)                as p_page_views
    ,format((google_analytics_partner_summaries.time_on_page/60/60)/(google_analytics_summaries.time_on_pages/60/60)*100,2)    as p_timeonpage
    
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