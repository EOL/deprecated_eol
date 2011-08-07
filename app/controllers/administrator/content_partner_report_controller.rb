class Administrator::ContentPartnerReportController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  helper :resources

  helper_method :current_agent, :agent_logged_in?

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("content_partners")
    @partner_search_string = params[:partner_search_string] || ''
    @only_show_agents_with_unpublished_content = EOLConvert.to_boolean(params[:only_show_agents_with_unpublished_content])
    @agent_status = AgentStatus.find(:all, :order => 'label')
    @agent_status_id = params[:agent_status_id] || AgentStatus.active.id
    where_clause = (@agent_status_id.blank? ? '' : "agent_status_id=#{@agent_status_id} AND ")
    search_string_parameter = '%' + @partner_search_string + '%'
    page = params[:page] || '1'
    order_by = params[:order_by] || 'full_name ASC'
    @agents = Agent.paginate_by_sql(["
      SELECT a.id, a.full_name, a.agent_status_id, partner_complete_step, show_on_partner_page, cp.vetted, cp.created_at
      FROM agents a
      JOIN content_partners cp on cp.agent_id=a.id
      WHERE #{where_clause} full_name like ?
      ORDER BY #{order_by}", search_string_parameter],:page => page)
  end

  def export
    @agents = Agent.find_by_sql('select a.* from agents a inner join content_partners cp on cp.agent_id=a.id order by a.full_name ASC')

    report = StringIO.new
    CSV::Writer.generate(report, ',') do |row|
        row << ['Partner Name', 'Registered Date', 'Resources','Status','Agent_ID']
        row << ['','Role', 'Contact', 'Email', 'Telephone','Address','Homepage']
        @agents.each do |agent|
          if agent.created_at.blank?
            created_at=''
          else
            created_at=agent.created_at.strftime("%m/%d/%y - %I:%M %p %Z")
          end if
          if agent.agent_status.blank?
            agent_status = 'unknown'
          else
            agent_status = agent.agent_status.label
          end
          row << [agent.project_name,agent.created_at,agent.resources.count,agent_status,agent.id]
          agent.agent_contacts.each do |contact|
            row << ['',contact.agent_contact_role.label,contact.title + ' ' + contact.full_name,contact.email,contact.telephone,contact.address,contact.homepage]
          end
          row << ''
        end
     end
     report.rewind
     send_data(report.read,:type=>'text/csv; charset=iso-8859-1; header=present',:filename => 'EOL_content_partners_export_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv', :disposition =>'attachment', :encoding => 'utf8')
     return false

  end

  def show
    @page_title = I18n.t("content_partner_detail")
    @agent = Agent.find_by_id(params[:id])
    if @agent.blank?
      redirect_to :action=>'index'
      return
    end
    @agent_status=AgentStatus.find(:all,:order=>'label')
    @agent.content_partner=ContentPartner.new if @agent.content_partner.nil?
    @current_agreement=ContentPartnerAgreement.find_by_agent_id_and_is_current(@agent.id,true,:order=>'created_at DESC')
    if @current_agreement == nil || @current_agreement.signed_by.blank?
      @agreement_signed='Not accepted'
    else
      @agreement_signed='Accepted by ' + @current_agreement.signed_by + '<br /> on ' + @current_agreement.signed_on_date.to_s
    end
  end

  def show_contacts
    @agent=Agent.find(params[:id],:include=>:agent_contacts)
    @page_title = I18n.t(:content_partner_contacts_page_title, :name => @agent.project_name)
    @contacts=@agent.agent_contacts
  end

  def edit_profile
    # TODO
  end

  def login_as_user
    @user = User.find_by_id(params[:id])
    if !@user.blank?
      reset_session
      self.current_user = @user
      redirect_to root_url
    end
  end

  def edit_agreement

    @page_title = I18n.t("edit_content_partner_agreement")
    @agent=Agent.find(params[:id])

    # if we are posting, create the new agreement
    if request.post?
      agreement=params[:agreement].merge(:agent_id=>@agent.id)
      @agreement=ContentPartnerAgreement.create_new(agreement)
      if @agreement.valid?
        flash[:notice]= I18n.t("content_partner_agreement_was_")
        redirect_to :action=>'show',:id=>params[:id]
        return
      end
    else
      # find their agreement
      @agreement=ContentPartnerAgreement.find_by_agent_id_and_is_current(@agent.id,true,:order=>'created_at DESC')

      # if this is the first time they are viewing the agreement, create it from the default template
      @agreement=ContentPartnerAgreement.create_new(:agent_id=>@agent.id) if @agreement.nil?

    end

    # find previous agreements
    @previous_agreements=ContentPartnerAgreement.find_all_by_agent_id_and_is_current(@agent.id,false,:order=>'created_at DESC')
    @primary_contact=@agent.primary_contact

  end

  def show_on_partner_page
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:show_on_partner_page)

    render_check_or_uncheck('show_on_cp_page_img', @agent.show_on_partner_page?)
  end

  def show_mou_on_partner_page
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:show_mou_on_partner_page)

    render_check_or_uncheck('show_mou_on_cp_page_img', @agent.show_mou_on_partner_page?)
  end

  def show_gallery_on_partner_page
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:show_gallery_on_partner_page)

    render_check_or_uncheck('show_gallery_on_cp_page_img', @agent.show_gallery_on_partner_page?)
  end

  def show_stats_on_partner_page
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:show_stats_on_partner_page)

    render_check_or_uncheck('show_stats_on_cp_page_img', @agent.show_stats_on_partner_page?)
  end


  def vet_partner
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:vetted)
    @agent.content_partner.set_vetted_status(@agent.vetted?)
    render_check_or_uncheck('vet_partner_img', @agent.vetted?)
  end

  def set_agent_status
    @agent = Agent.find(params[:id])
    @agent.agent_status_id = params[:agent_status_id]
    @agent.save!
    render :nothing=>true
  end

  def auto_publish
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:auto_publish)

    render_check_or_uncheck('auto_publish_img', @agent.auto_publish?)
  end

  def monthly_stats_email
    last_month = Time.now - 1.month
    @year = last_month.year.to_s
    @month = last_month.month.to_s

    Agent.content_partners_contact_info(@month,@year).each do |recipient|
      Notifier.deliver_monthly_stats(recipient,@month,@year)
    end

    #for testing the query result
    @rset = Agent.content_partners_contact_info(@month,@year)
  end

  def get_year_month_list()
    arr=[]
    start="2008_01"
    str=""
    var_date = Time.now
    while( start != str)
      str = var_date.year.to_s + "_" + "%02d" % var_date.month.to_s
      arr << str
      var_date = var_date - 1.month
    end
    return arr
  end

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
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
    end
    page = params[:page] || 1
    @published_content_partners = ContentPartner.partners_published_in_month(@report_year, @report_month)
  end


  def report_partner_curated_data
    @page_header = 'Content Partner Curated Data'
    @year_month_list = get_year_month_list()

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
      last_month = Time.now
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
    end

    if(params[:content_partner_id]) then
      @content_partner_id = params[:content_partner_id]
      session[:form_content_partner_id] = params[:content_partner_id]
    elsif(session[:form_content_partner_id]) then
      @content_partner_id = session[:form_content_partner_id]
    else
      @content_partner_id = "All"
    end

    @content_partners_with_published_data = ContentPartner.with_published_data

    if @content_partner_id == "All"
      @partner_fullname = "All Curation"
      arr_dataobject_ids = []
    else
      content_partner = ContentPartner.find(@content_partner_id)
      @partner_fullname = content_partner.user.full_name
      latest_harvest_event = content_partner.resources.first.latest_harvest_event
      arr_dataobject_ids = HarvestEvent.data_object_ids_from_harvest(latest_harvest_event.id)
    end

    arr = User.curated_data_object_ids(arr_dataobject_ids, @report_year, @report_month, @content_partner_id)
    @arr_dataobject_ids = arr[0]
    @arr_user_ids = arr[1]

    if @arr_dataobject_ids.length == 0
      @arr_dataobject_ids = [1] #no data objects
    end

    @arr_obj_tc_id = DataObject.tc_ids_from_do_ids(@arr_dataobject_ids);
    page = params[:page] || 1
    @partner_curated_objects = User.curated_data_objects(@arr_dataobject_ids, @report_year, @report_month, page, "report")

    @cur_page = (page.to_i - 1) * 30
  end

  def report_partner_objects_stats
    @page_header = 'Content Partner Data Objects Stats'

    if !params[:agent_id].blank? && params[:agent_id] != 0
      @agent_id = params[:agent_id]
      session[:form_agent_id] = params[:agent_id]
    elsif !session[:form_agent_id].blank? && session[:form_agent_id] != 0
      @agent_id = session[:form_agent_id]
    else
      @agent_id = 1  # default
    end

    @content_partners_with_published_data = Agent.content_partners_with_published_data
    if @agent_id == "All"
      @agent_id = 1
    end
    partner = Agent.find(@agent_id, :select => 'full_name')
    @partner_fullname = partner.full_name

    page = params[:page] || 1
    @partner_harvest_events = Agent.resources_harvest_events(@agent_id, page)

    @cur_page = (page.to_i - 1) * 30
  end

  def show_data_object_stats
    @harvest_id = params[:harvest_id]
    @partner_fullname = params[:partner_fullname]

    @page_header = 'Harvest Event Data Objects Stats'
    @data_objects, @total_taxa = DataObject.generate_dataobject_stats(@harvest_id)
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

  def render_check_or_uncheck(div, test)
    render :update do |page|
      if test
        page << "$('##{div}').attr('src', '/images/checked.png')"
      else
        page << "$('##{div}').attr('src', '/images/not-checked.png')"
      end
    end
  end

end
