class GoogleAnalyticsPartnerSummary < ActiveRecord::Base
  belongs_to :user
  self.primary_keys = :year, :month, :user_id
  
  def time_on_page_in_hours
    time_on_page.to_f / 60.0 / 60.0
  end
  
  def percent_overall_taxa_pages(google_analytics_summary)
    (taxa_pages.to_f / google_analytics_summary.taxa_pages.to_f) * 100.0
  end
  
  def percent_overall_taxa_pages_viewed(google_analytics_summary)
    (taxa_pages_viewed.to_f / google_analytics_summary.taxa_pages_viewed.to_f) * 100.0
  end
  
  def percent_overall_unique_page_views(google_analytics_summary)
    (unique_page_views.to_f / google_analytics_summary.unique_pageviews.to_f) * 100.0
  end
  
  def percent_overall_page_views(google_analytics_summary)
    (page_views.to_f / google_analytics_summary.pageviews.to_f) * 100.0
  end
  
  def percent_overall_time_on_page_in_hours(google_analytics_summary)
    (time_on_page_in_hours / google_analytics_summary.time_on_pages_in_hours) * 100.0
  end
end
