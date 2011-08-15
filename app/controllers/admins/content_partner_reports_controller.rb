class Admins::ContentPartnerReportsController < AdminsController

  helper :resources
  helper_method :current_agent, :agent_logged_in?
  before_filter :restrict_to_admins

  def report_monthly_published_partners
    @page_title = I18n.t("published_content_partners")
    @year_month_list = get_year_month_list()
    if(params[:year_month]) then
      params[:year], params[:month] = params[:year_month].split("_") if params[:year_month]
      @report_year  = params[:year].to_i
      @report_month = params[:month].to_i
      @year_month   = params[:year] + "_" + "%02d" % params[:month].to_i
    else
      last_month = Time.now - 1.month
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month = @report_year + "_" + "%02d" % @report_month.to_i
    end
    page = params[:page] || 1
    @published_content_partners = ContentPartner.partners_published_in_month(@report_year, @report_month)
  end

  private
 
  def get_year_month_list()
    arr = []
    start = "2008_01"
    str = ""
    var_date = Time.now
    while( start != str)
      str = var_date.year.to_s + "_" + "%02d" % var_date.month.to_s
      arr << str
      var_date = var_date - 1.month
    end
    return arr
  end 

end