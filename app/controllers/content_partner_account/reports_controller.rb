class ContentPartnerAccount::ReportsController < ContentPartnerAccountController
  before_filter :check_authentication
  layout 'user_profile'

  def index
    @page_header = I18n.t("usage_reports")
    content_partner = ContentPartner.find_by_user_id(current_user.id)
    @no_resources = !content_partner.has_published_resources?
  end

  def page_stats
    @page_header = I18n.t("usage_reports")
    content_partner = ContentPartner.find_by_user_id(current_user.id)
    @no_resources = content_partner.has_published_resources?
    @agent_id = current_agent.id
    last_month = Time.now - 1.month
    report_year = last_month.year.to_s
    report_month = "%02d" % last_month.month.to_s
    @report_date = "#{report_year}_#{report_month}"
    @report_type = :page_stats
  end

  def monthly_page_stats
    @page_header = I18n.t("usage_reports")
    page = params[:page] || 1

    if(params[:year_month]) then
      @year_month = params[:year_month]
      session[:form_year_month] = params[:year_month]
    elsif(session[:form_year_month]) then
      @year_month = session[:form_year_month]
    end
    if(@year_month) then
      params[:year], params[:month] = @year_month.split("_")
      @report_year  = params[:year].to_i
      @report_month = params[:month].to_i
      @year_month   = params[:year] + "_" + "%02d" % params[:month].to_i
    else
      last_month = Time.now - 1.month
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
    end

    if(params[:user_id]) then
      @user_id = params[:user_id]
      session[:form_user_id] = params[:user_id]
    elsif(session[:form_user_id]) then
      @user_id = session[:form_user_id]
    else
      @user_id = current_user.id
    end

    if(@year_month <= "2009_11") then
      temp = page_stats
      @report_date = @year_month
      @user_id = params[:user_id]
      render :action => "page_stats"
    end

    @content_partners_with_published_data = ContentPartner.with_published_data
    @content_partner = ContentPartner.find_by_user_id(@user_id)
    @partner_summary = GoogleAnalyticsPartnerSummary.find_by_user_id_and_year_and_month(@user_id, @report_year, @report_month)
    @overall_summary = GoogleAnalyticsSummary.find_by_year_and_month(@report_year, @report_month)

    @posts = GoogleAnalyticsPageStat.page_summary(@user_id, @report_year, @report_month, page)
  end

  def data_object_stats
    @page_header = I18n.t("usage_reports")
    content_partner = ContentPartner.find_by_user_id(current_user.id)
    @no_resources = !content_partner.has_published_resources?
    @agent_id = current_agent.id
    @report_type = :data_object_stats
  end

  def no_resources
  end

  def admin_whole_report
    @page_header = I18n.t("usage_reports")
    @curator_logs = CuratorActivityLog.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25", :order => 'created_at DESC')
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :admin_whole_report

    render :template => 'content_partner/reports/whole_report'
  end

  #part below is for a content partner
  def whole_report
    @page_header = I18n.t("usage_reports")
    content_partner   = ContentPartner.find_by_user_id(current_user.id)
    curator_logs     = (content_partner.comments_curator_activity_log + content_partner.data_objects_curator_activity_log).sort{|a,b| b.updated_at <=> a.updated_at}
    @curator_logs    = curator_logs.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :whole_report
  end

  def comments_report
    @page_header = I18n.t("usage_reports")
    content_partner   = ContentPartner.find_by_user_id(current_user.id)
    @curator_logs    = content_partner.comments_curator_activity_log.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of comments'
    @report_type      = :comments_report
  end

  def taxa_comments_report
    @page_header = I18n.t("usage_reports")
    content_partner   = ContentPartner.find_by_user_id(current_user.id)
    @comments    = content_partner.taxa_comments.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Comments on Taxa'
    @report_type      = :taxa_comments_report
  end

  def statuses_report
    @page_header = I18n.t("usage_reports")
    content_partner   = ContentPartner.find_by_user_id(current_user.id)
    @curator_logs    = content_partner.data_objects_curator_activity_log.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status'
    @report_type      = :statuses_report
  end

end
