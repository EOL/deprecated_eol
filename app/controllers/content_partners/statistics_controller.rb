class ContentPartners::StatisticsController < ContentPartnersController

  # GET /content_partners/:content_partner_id/statistics
  def show
    @partner = ContentPartner.find(params[:content_partner_id], :include => :user)
    @page = params[:page] || 1
    last_month = Date.today - 1.month
    @year = (params[:date].blank? || params[:date][:year].blank?) ? last_month.year : params[:date][:year]
    @month = (params[:date].blank? || params[:date][:month].blank?) ? last_month.month : params[:date][:month]
    @partner_summary = @partner.user.google_analytics_partner_summaries.find_by_year_and_month(@year, @month)
    @site_summary = GoogleAnalyticsSummary.find_by_year_and_month(@year, @month)
    @pages = GoogleAnalyticsPageStat.page_summary(@partner.user.id, @year, @month, @page)
    @month_name = Date::MONTHNAMES[@month.to_i]
  end
end