require File.dirname(__FILE__) + '/../spec_helper'

def mock_agent(options = {})
  mock_model(Agent, {
    :access_step? => false, 
    :project_name => '', 
    :full_name => '', 
    :project_abbreviation => '',
    :url => '',
    :display_name => '',
    :project_description => '',
    :logo_url => '',
    :notes => '',
    :logo? => false,
    :description_of_data => '',
    :agent_data_type_ids => '',
    :content_partner => mock_model(ContentPartner),
    :vetted => false}.merge(options))
end

describe ContentPartnerController do
  fixtures :agents
  fixtures :content_partners
  
  # Authentication
  # ---------------------------------------------------------------
  
  describe "GET /register" do
    it "should succeed" do
      get :register
      response.should be_success
      assigns[:agent].should_not be_nil
    end
  end
  
  describe "POST /register" do
    it "should succeed on unsuccessful save" do
      post :register, :agent => nil
      response.should be_success
      assigns[:agent].should_not be_valid
    end

    it "should redirect to index on successful save" do
      @agent = mock(:agent)
      @agent.should_receive(:save).and_return(true)
      @agent.should_receive(:agent_status=)
      Agent.should_receive(:new).with('agent').and_return(@agent)
      mock_cp = mock_model(ContentPartner)
      ContentPartner.should_receive(:new).and_return(mock_cp)
      @agent.should_receive(:content_partner=).with(mock_cp)
      
      post :register, :agent => 'agent'
      response.should redirect_to("http://test.host/content_partner")
      assigns[:current_agent].should == @agent
    end
  end

  describe "GET /login" do
    it "should succeed" do
      get :login
      response.should be_success
    end
  end
  
  describe "POST /login" do
    it "should render with flash error on unsuccessful login" do
      post :login, :agent => { :username => 'quentin', :password => 'bad password' }
      response.should be_success
      session[:agent_id].should be_nil
      flash.now[:error].should_not be_nil
    end
        
    it "should redirect to index on success" do
      post :login, :agent => { :username => 'quentin', :password => 'test' }
      session[:agent_id].should_not be_nil
      response.should be_redirect
    end
  end
  
  describe "GET /logout" do
    it "should clear agent id and redirect" do
      login_as_agent :quentin
      session[:agent_id].should_not be_nil
      get :logout
      session[:agent_id].should be_nil
      response.should be_redirect
    end
  end
  
  describe "GET /index" do
    it "should require a login" do
      get :index
      response.should be_redirect
    end
    
    it "should succeed" do
      login_as_agent :quentin
      get :index
      response.should be_success
    end
  end
  
  describe "POST /check_username" do
    integrate_views
    it "should succeed" do
      post :check_username, :username => 'blah'
      response.should be_success
    end

    it "should update #username_warn with nothing on unmatched username" do
      post :check_username, :username => 'blah'
      response.body.should == %{$("username_warn").update("");}
    end
    
    it "should update #username_warn with message on matched username" do
      @agent = mock(:agent, :username => 'hello')
      Agent.should_receive(:find_by_username).with('hello', {:conditions => ""}).and_return @agent
      
      post :check_username, :username => 'hello'
      response.body.should =~ /hello/      
    end
  end
  
  describe "GET /forgot_password" do
    it "should succeed" do
      get :forgot_password
      response.should be_success      
    end
  end
  
  describe "POST /forgot_password" do
    it "should redirect back with flash[:error] on unsuccessful reset" do
      post :forgot_password
      response.should redirect_to({ :action => 'forgot_password' })
      flash[:error].should_not be_nil
    end
    
    it "should redirect to login with flash notice and send email on successful reset" do
      @agent = mock_agent(:email => 'test@example.com', :username => 'test', :full_name => 'Some Project')
      @agent.should_receive(:reset_password!).and_return('newPassword!')
      Agent.should_receive(:find_by_username_and_email).with('test', 'test@example.com').and_return(@agent)
      Notifier.should_receive(:deliver_agent_forgot_password_email)
      post :forgot_password, :email => 'test@example.com', :username => 'test'
      
      flash[:notice].should_not be_nil
      response.should redirect_to({ :action => 'login' })
    end
  end

  describe "GET /profile" do
    it "should succeed" do
      login_as_agent :quentin
      get :profile
      response.should be_success
      assigns[:agent].should_not be_nil
    end 
  end
  
  describe "POST /profile" do
    before(:each) do
      @agent = mock_agent
      login_as_agent :quentin
    end
  
    it "should redirect back with flash notice on successful save" do
      post :profile, :agent => {}
      flash[:notice].should_not be_nil
      response.should redirect_to(:action => 'profile')
    end
    
    it "should render on unsuccessful save" do
      post :profile, :agent => { :email => nil }
      flash[:notice].should be_nil
      assigns[:agent].should_not be_valid
      response.should be_success
    end
  end
  
  # Steps
  # ---------------------------------------------------------------
  
  describe "GET /partner" do
    it "should succeed" do
      login_as_agent :quentin
      get :partner
      response.should be_success
    end
  end
  
  describe "POST /partner" do
    before(:each) do
      @agent = mock_agent
      @agent.content_partner.should_receive(:step=).with(:partner)      
      @agent.should_receive(:partner_step=).with(true)
      @agent_hash = {:project_name=>'Peter',:display_name=>'Test Project',:project_description=>'This is the test project'}
    end

    it "should redirect to contacts on successful save by default" do
      @agent.should_receive(:update_attributes).and_return(true)
      @agent.content_partner.should_receive(:log_completed_step!)
      @agent.stub!(:logo_file_name).and_return('') # Keeps it from doing anything else 
                                                   # TODO - test that that other stuff works! controller line 36 or so.
      controller.stub!(:current_agent).and_return(@agent)

      post :partner, :agent => @agent_hash
      response.should redirect_to(:action => 'contacts')    
    end
    
    it "should render on unsuccessful save" do
      @agent.should_receive(:update_attributes).and_return(false)
      @agent.content_partner.should_not_receive(:log_completed_step!)
      controller.stub!(:current_agent).and_return(@agent)
      post :partner, :agent => @agent_hash
      response.should be_success
    end
  end
  
  describe "GET /contacts" do
    it "should succeed" do
      step_should_succeed(:contacts, 'partner')
    end    
  end
  
  describe "POST /contacts" do
    before(:each) do
      @agent_contacts = mock(:agent_contacts)
      @agent_contacts.should_receive(:find).with(:all, :include => :agent_contact_role).and_return([])

      @agent = mock_agent(:access_step? => false, :agent_contacts => @agent_contacts, :log_completed_step! => nil)
      @agent.content_partner.should_receive(:step=).with(:contacts)
    end
    
    it "should redirect to licensing on successful save by default" do
      @agent.should_receive(:update_attributes).and_return(true)
      @agent.content_partner.should_receive(:log_completed_step!)
      controller.stub!(:current_agent).and_return(@agent)

      post :contacts, :agent => 'agent'
      response.should redirect_to(:action => 'licensing')    
    end
    
    it "should render on unsuccessful save" do
      @agent.should_receive(:update_attributes).and_return(false)
      @agent.content_partner.should_not_receive(:log_completed_step!)
      controller.stub!(:current_agent).and_return(@agent)
      post :contacts, :agent => 'agent'
      response.should be_success
    end
  end

  describe "GET /licensing" do
    it "should succeed" do
      step_should_succeed(:licensing, 'contacts')
    end    
  end
  
  describe "POST /licensing" do    
    before(:each) do
      @agent = mock_agent(:access_step? => false, :ipr_accept => 0)
      @agent.content_partner.should_receive(:step=).with(:licensing)
    end
    
    it "should redirect to attribution on successful save" do      
      post_step_should_redirect(@agent, :licensing, 'attribution')      
    end
    
    it "should render on unsuccessful save" do      
      post_step_should_render(@agent, :licensing)
    end
  end

  describe "GET /attribution" do
    it "should succeed" do
      step_should_succeed(:attribution, 'licensing')
    end
  end

  describe "POST /attribution" do    
    before(:each) do
      @agent = mock_agent(:access_step? => false, :attribution_accept => 0)
      @agent.content_partner.should_receive(:step=).with(:attribution)
    end
    
    it "should redirect to roles on successful save" do      
      post_step_should_redirect(@agent, :attribution, 'roles')      
    end
    
    it "should render on unsuccessful save" do      
      post_step_should_render(@agent, :attribution)
    end
  end
  
  describe "GET /roles" do
    it "should succeed" do
      step_should_succeed(:roles, 'attribution')
    end    
  end
  
  describe "POST /roles" do    
    before(:each) do
      @agent = mock_agent(:access_step? => false, :roles_accept => 0, :project_name => '')
      @agent.content_partner.should_receive(:step=).with(:roles)
    end
    
    it "should redirect to transfer on successful save" do      
      post_step_should_redirect(@agent, :roles, 'transfer_overview')      
    end
    
    it "should render on unsuccessful save" do      
      post_step_should_render(@agent, :roles)
    end
  end
  
  describe "GET /transfer_overview" do
    it "should succeed" do
      step_should_succeed(:transfer_overview, 'roles')
    end
  end
  
  describe "POST /transfer_overview" do    
    before(:each) do
      @agent = mock_agent(:access_step? => false)
      @agent.content_partner.should_receive(:step=).with(:transfer_overview)
    end
    
    it "should redirect to transfer_upload on successful save by default" do      
      post_step_should_redirect(@agent, :transfer_overview, 'transfer_upload')      
    end
    
    it "should render on unsuccessful save" do      
      post_step_should_render(@agent, :transfer_overview)
    end
  end  
  
    
  # Contact crud
  # ----------------------------------------------
  
  describe "GET /add_contact" do
    it "should succeed" do
      login_as_agent :quentin
      get :add_contact
      response.should be_success
    end
  end

  describe "POST /add_contact" do
    before(:each) do
      @agent_contact = mock_model(AgentContact, :family_name=>nil, :full_name=>nil, :telephone=>nil, :email=>nil, :agent_contact_role_id=>nil, :homepage=>nil, :given_name=>nil, :title=>nil, :address=>nil, :agent_id=>nil)
      @current_agent_contacts = mock(:agent_contact)
      @current_agent_contacts.should_receive(:build).with('params').and_return(@agent_contact)
      
      @agent = mock_agent(:agent_contacts => @current_agent_contacts, :vetted_for_agreement? => false, :full_name => 'Some Project')
      controller.stub!(:current_agent).and_return(@agent)
    end

    it "should redirect to contacts on successful save" do      
      @agent_contact.should_receive(:save).and_return(true)

      post :add_contact, :agent_contact => 'params'
      response.should redirect_to(:action => 'contacts')
      flash[:notice].should_not be_nil
    end
    
    it "should render on unsuccessful save" do
      @agent_contact.should_receive(:save).and_return(false)

      post :add_contact, :agent_contact => 'params'
      response.should be_success
    end
  end

  describe "GET /edit_contact" do
    it "should succeed" do
      @agent_contact = mock_model(AgentContact, :family_name=>nil, :full_name=>nil, :telephone=>nil, :email=>nil, :agent_contact_role_id=>nil, :homepage=>nil, :given_name=>nil, :title=>nil, :address=>nil, :agent_id=>nil)
      @current_agent_contacts = mock(:agent_contact)
      @current_agent_contacts.should_receive(:find).with('id').and_return(@agent_contact)
      
      @agent = mock_agent(:agent_contacts => @current_agent_contacts, :vetted_for_agreement? => false, :full_name => 'Some Project')
      controller.stub!(:current_agent).and_return(@agent)
      
      get :edit_contact, :id => 'id'
      response.should be_success
    end
  end

  describe "POST /edit_contact" do
    before(:each) do
      @agent_contact = mock_model(AgentContact, :family_name=>nil, :full_name=>nil, :telephone=>nil, :email=>nil, :agent_contact_role_id=>nil, :homepage=>nil, :given_name=>nil, :title=>nil, :address=>nil, :agent_id=>nil)
      @current_agent_contacts = mock(:agent_contact)
      @current_agent_contacts.should_receive(:find).with('id').and_return(@agent_contact)
      
      @agent = mock_agent(:agent_contacts => @current_agent_contacts, :vetted_for_agreement? => false, :full_name => 'Some Project')
      controller.stub!(:current_agent).and_return(@agent)      
    end
    
    it "should redirect to contacts on successful save" do
      @agent_contact.should_receive(:update_attributes).with('agent_contact').and_return(true)
      post :edit_contact, :id => 'id', :agent_contact => 'agent_contact'
      response.should redirect_to(:action => 'contacts')
      flash[:notice].should_not be_nil
    end
    
    it "should render on unsuccessful save" do
      @agent_contact.should_receive(:update_attributes).with('agent_contact').and_return(false)
      post :edit_contact, :id => 'id', :agent_contact => 'agent_contact'
      response.should be_success
    end
  end

  describe "GET /del_contact" do
    before(:each) do
      @agent_contact = mock_model(AgentContact)
      @current_agent_contacts = mock(:agent_contact)
      @current_agent_contacts.should_receive(:find).with('id').and_return(@agent_contact)
      
      @agent = mock_agent(:agent_contacts => @current_agent_contacts, :full_name => 'Some Project')
      controller.stub!(:current_agent).and_return(@agent)            
    end
    it "should redirect to contacts on successful delete" do
      @current_agent_contacts.should_receive(:count).and_return(2)
      @agent_contact.should_receive(:destroy)

      get :del_contact, :id => 'id'
      flash[:notice].should_not be_nil
      response.should redirect_to(:action => 'contacts')
    end
    
    it "should not delete last contact" do
      @current_agent_contacts.should_receive(:count).and_return(1)

      get :del_contact, :id => 'id'
      flash[:error].should_not be_nil
      response.should redirect_to(:action => 'contacts')
    end
  end

  protected
  
    def post_step_should_redirect(agent, action, redirect_action)
      @agent.content_partner.should_receive(:update_attributes).and_return(true)
      @agent.content_partner.should_receive(:log_completed_step!)
      controller.stub!(:current_agent).and_return(@agent)

      post action, :agent => 'agent'
      response.should redirect_to(:action => redirect_action)    
    end
    
    def post_step_should_render(agent, action)
      @agent.content_partner.should_receive(:update_attributes).and_return(false)
      @agent.content_partner.should_not_receive(:log_completed_step!)
      controller.stub!(:current_agent).and_return(@agent)
      post action, :agent => 'agent'
      response.should be_success
    end
    
  
    def step_should_succeed(action, last_completed_step)
      #agents(:quentin).update_attribute(:last_completed_step, last_completed_step)
      login_as_agent :quentin
      get(action)
      response.should be_success      
    end
    
    def step_should_redirect(action, last_completed_step)
      agents(:quentin).update_attribute(:last_completed_step, last_completed_step)
      login_as_agent :quentin
      get(action)
      flash[:warning].should_not be_nil
      response.should be_redirect      
    end
  
    def login_as_agent(agent)
      @request.session[:agent_id] = agents(agent).id
    end
end
