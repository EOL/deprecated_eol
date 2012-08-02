class GoogleAnalyticsSummary < ActiveRecord::Base
  self.primary_keys :year, :month
  
  def time_on_pages_in_hours
    time_on_pages.to_f / 60.0 / 60.0
  end
end
