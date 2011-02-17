class ContentPartner::ReportsController < ContentPartnerController
  layout 'content_partner'
    
  def index
    @page_header = 'Usage Reports'
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = !content_partner.has_published_resources?
  end  
  
  def page_stats
    @page_header = 'Usage Reports'
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = content_partner.has_published_resources?
    @agent_id = current_agent.id
    last_month = Time.now - 1.month
    report_year = last_month.year.to_s
    report_month = "%02d" % last_month.month.to_s
    @report_date = "#{report_year}_#{report_month}"
    @report_type = :page_stats
  end
  
  def monthly_page_stats
    @page_header = 'Usage Reports'
    
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

    if(params[:agent_id]) then
      @agent_id = params[:agent_id]
      session[:form_agent_id] = params[:agent_id]
    elsif(session[:form_agent_id]) then
      @agent_id = session[:form_agent_id]
    else
      @agent_id = current_agent.id
    end    
    
    if(@year_month <= "2009_11") then
      temp = page_stats
      @report_date = @year_month
      @agent_id = params[:agent_id]
      render :action => "page_stats"      
    end
    
    @content_partners_with_published_data = Agent.content_partners_with_published_data  
    @partner = Agent.find(@agent_id, :select => 'full_name')
    @recs = GoogleAnalyticsPartnerSummary.summary(@agent_id, @report_year, @report_month)            
    page = params[:page] || 1
    @posts = GoogleAnalyticsPageStat.page_summary(@agent_id, @report_year, @report_month, page)    
  end
  
  def data_object_stats
    @page_header = 'Usage Reports'
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = !content_partner.has_published_resources?
    @agent_id = current_agent.id
    @report_type = :data_object_stats
  end
  
  def no_resources
  end
  
  def admin_whole_report
    @page_header = 'Usage Reports'
    @act_histories = ActionsHistory.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25", :order => 'created_at DESC')
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :admin_whole_report
    
    render :template => 'content_partner/reports/whole_report'
  end
  
  #part below is for a content partner
  def whole_report
    @page_header = 'Usage Reports'
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    act_histories     = (content_partner.comments_actions_history + content_partner.data_objects_actions_history).sort{|a,b| b.updated_at <=> a.updated_at}
    @act_histories    = act_histories.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :whole_report
  end
  
  def comments_report
    @page_header = 'Usage Reports'
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    @act_histories    = content_partner.comments_actions_history.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of comments'
    @report_type      = :comments_report
  end

  def taxa_comments_report
    @page_header = 'Usage Reports'
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    @act_histories    = content_partner.taxa_comments_actions_history.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Comments on Taxa'
    @report_type      = :taxa_comments_report
  end
  
  def statuses_report
    @page_header = 'Usage Reports'
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    @act_histories    = content_partner.data_objects_actions_history.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status'
    @report_type      = :statuses_report
  end

end
