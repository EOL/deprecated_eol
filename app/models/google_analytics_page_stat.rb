class GoogleAnalyticsPageStat < ActiveRecord::Base
  belongs_to :taxon_concept
  self.primary_keys = :taxon_concept_id, :year, :month, :page_views

  def self.page_summary(user_id, year, month, page)
    query =  "SELECT gapt.taxon_concept_id,
              SUM(gaps.page_views) page_views,
              SUM(gaps.unique_page_views) unique_page_views,
              SUM(TIME_TO_SEC(gaps.time_on_page)) `timeonpage`
              FROM google_analytics_page_stats gaps
              JOIN google_analytics_partner_taxa gapt ON (gapt.taxon_concept_id = gaps.taxon_concept_id AND gapt.`year` = gaps.`year` AND gapt.`month` = gaps.`month`)
              WHERE gapt.user_id = ? AND
              gapt.`year` = ? AND
              gapt.`month` = ?
              GROUP BY
              gapt.taxon_concept_id,
              gapt.user_id,
              gapt.`year`,
              gapt.`month`
              ORDER BY SUM(gaps.page_views) DESC "
    self.paginate_by_sql [query, user_id, year, month], page: page, per_page: 50 , order: 'SUM(gaps.page_views)'
  end
end
