class ContentPartner::ReportsController < ContentPartnerController
  include ReportsControllerModule

  layout 'content_partner'
  
  
  
  def index
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = !content_partner.has_published_resources?
  end  
  
  def page_stats
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = content_partner.has_published_resources?
    @agent_id = current_agent.id
    last_month = Time.now - 1.month
    report_year = last_month.year.to_s
    report_month = "%02d" % last_month.month.to_s
    @report_date = "#{report_year}_#{report_month}"
    @report_type = :page_stats
  end
  
  def data_object_stats
    content_partner = ContentPartner.find_by_agent_id(current_agent.id)
    @no_resources = !content_partner.has_published_resources?
    @agent_id = current_agent.id
    @report_type = :data_object_stats
  end
  
  def no_resources
  end
  
  def admin_whole_report
    @act_histories = ActionsHistory.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25", :order => 'created_at DESC')
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :admin_whole_report
    
    render :template => 'content_partner/reports/whole_report'
  end
  
  #part below is for a content partner
  def whole_report
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    act_histories     = (content_partner.comments_actions_history + content_partner.data_objects_actions_history).sort{|a,b| b.updated_at <=> a.updated_at}
    @act_histories    = act_histories.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :whole_report
  end
  
  def comments_report
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    @act_histories    = content_partner.comments_actions_history.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of comments'
    @report_type      = :comments_report
  end
  
  def statuses_report
    content_partner   = ContentPartner.find_by_agent_id(current_agent.id)
    @act_histories    = content_partner.data_objects_actions_history.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || "25")
    @sub_page_header  = 'Changing of objects status'
    @report_type      = :statuses_report
  end

end
