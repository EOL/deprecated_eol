class Administrator::ContentPartnerReportController < AdminController
  helper :resources
  helper_method :current_agent, :agent_logged_in?
  
  access_control :DEFAULT => 'Administrator - Content Partners'
  
  def index
    @partner_search_string=params[:partner_search_string] || ''
    search_string_parameter='%' + @partner_search_string + '%' 
    page=params[:page] || '1'
    order_by=params[:order_by] || 'full_name ASC'
    @agents = Agent.paginate(:order => order_by, :conditions=>['full_name like ? AND username <>""',search_string_parameter],:page => page, :include=>:content_partner)
  end

  def show
    @agent = Agent.find_by_id(params[:id])
    if @agent.blank?
      redirect_to :action=>'index' 
      return
    end
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
    @contacts=@agent.agent_contacts
  end

  def edit_profile

    @agent=Agent.find(params[:id],:include=>:content_partner)   
    return unless request.post?

    if @agent.update_attributes(params[:agent])

      upload_logo(@agent) unless @agent.logo_file_name.blank?
      flash[:notice] = "Profile updated"[]
      redirect_to :action => 'show',:id=>@agent.id 

    end
      
  end
  
  def login_as_agent
      
    @agent=Agent.find_by_id(params[:id])   
    
    if !@agent.blank?
      reset_session
      self.current_agent=@agent
      redirect_to :controller=>'/content_partner',:action=>'index'
    end
    return
      
  end
  
  def edit_agreement
    
    @agent=Agent.find(params[:id])

    # if we are posting, create the new agreement
    if request.post?
      agreement=params[:agreement].merge(:agent_id=>@agent.id)
      @agreement=ContentPartnerAgreement.create_new(agreement)
      if @agreement.valid?
        flash[:notice]='Content partner agreement was updated.'
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

    render :update do |page|
      if @agent.show_on_partner_page?
        page << "$('show_on_cp_page_img').src = '/images/checked.png'"
      else
        page << "$('show_on_cp_page_img').src = '/images/not-checked.png'"
      end
    end
  end

  def show_mou_on_partner_page
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:show_mou_on_partner_page)

    render :update do |page|
      if @agent.show_mou_on_partner_page?
        page << "$('show_mou_on_cp_page_img').src = '/images/checked.png'"
      else
        page << "$('show_mou_on_cp_page_img').src = '/images/not-checked.png'"
      end
    end
  end
  
  def vet_partner
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:vetted)
    @agent.content_partner.set_vetted_status(@agent.content_partner.vetted)
    render :update do |page|
      if @agent.vetted?
        page << "$('vet_partner_img').src = '/images/checked.png'"
      else
        page << "$('vet_partner_img').src = '/images/not-checked.png'"
      end
    end
  end

  def auto_publish
    @agent = Agent.find(params[:id])
    @agent.content_partner.toggle!(:auto_publish)

    render :update do |page|
      if @agent.auto_publish?
        page << "$('auto_publish_img').src = '/images/checked.png'"
      else
        page << "$('auto_publish_img').src = '/images/not-checked.png'"
      end
    end
  end

end
