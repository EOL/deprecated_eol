class ContentPartners::StatisticsController < ContentPartnersController

  # GET /content_partners/:content_partner_id/statistics
  def show
    @partner = ContentPartner.find(params[:content_partner_id],
                                   :include => [ :user, :resources ],
                                   :select => 'content_partners.*, users.id, resources.id')
    @page = params[:page] || 1
    last_month = Date.today - 1.month
    @year = (params[:date].blank? || params[:date][:year].blank?) ? last_month.year : params[:date][:year]
    @month = (params[:date].blank? || params[:date][:month].blank?) ? last_month.month : params[:date][:month]
    @partner_summary = @partner.user.google_analytics_partner_summaries.find_by_year_and_month(@year, @month)
    @site_summary = GoogleAnalyticsSummary.find_by_year_and_month(@year, @month)
    @pages = GoogleAnalyticsPageStat.page_summary(@partner.user.id, @year, @month, @page)
    GoogleAnalyticsPageStat.preload_associations(@pages, { :taxon_concept => { :published_hierarchy_entries => [ :name, :hierarchy ] } } )
    @month_name = Date::MONTHNAMES[@month.to_i]
    @rel_canonical_href = content_partner_statistics_url(@partner, :page => rel_canonical_href_page_number(@pages))
    @rel_prev_href = rel_prev_href_params(@pages) ? content_partner_statistics_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@pages) ? content_partner_statistics_url(@rel_next_href_params) : nil
  end
end