require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def mock_agent_for_resource
  @mock_agent = mock_model(Agent, :resources => [])
  @mock_agent.stub!(:ready_for_agreement?).and_return(true)
  return @mock_agent
end

describe ResourcesController do
  describe "handling GET /resources" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource)
      #@resource.should_receive(:agents).and_return([@mock_agent])
      Resource.stub!(:find).and_return([@resource])
    end
  
    def do_get(options = {:agent => true})
      if options[:agent]
        session[:agent_id] = @mock_agent.id 
        controller.stub!(:current_agent).and_return(@mock_agent)
      end
      @mock_agent.stub!(:resources).and_return([@resource])
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end

    it 'should call current_agent using cookie' do
      controller.stub!(:cookies).and_return({:agent_auth_token => 1})
      @mock_agent.should_receive(:remember_token).and_return(1)
      @mock_agent.should_receive(:remember_token_expires_at).and_return(1.day.from_now)
      @mock_agent.should_receive(:remember_token?).and_return(true)
      Agent.should_receive(:find_by_remember_token).with(1).and_return(@mock_agent)
      do_get(:agent => false)
    end
  
    it 'should call current_agent using session id' do
      session[:agent_id] = 1
      Agent.should_receive(:find_by_id).with(1).and_return(@mock_agent)
      do_get(:agent => false)
    end
  
    it "should find all resources" do
      @mock_agent.should_receive(:resources).and_return([@resource])
      do_get
    end
  
    it "should assign the found resources for the view" do
      do_get
      assigns[:resources].should == [@resource]
    end
  end

  describe "handling GET /resources/1" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :agents => [@mock_agent])
      Resource.should_receive(:find).with(@resource.id.to_s).and_return(@resource)
      @mock_agent.stub!(:resources).and_return(@resource)
    end
  
    def do_get
      controller.stub!(:current_agent).and_return(@mock_agent)
      get :show, :id => @resource.id
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render show template" do
      do_get
      response.should render_template('show')
    end
  
    it "should assign the found resource for the view" do
      do_get
      assigns[:resource].should equal(@resource)
    end
  end

  describe "handling GET /resources/new" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :agents => [@mock_agent])
      Resource.stub!(:new).and_return(@resource)
    end
  
    def do_get
      controller.stub!(:current_agent).and_return(@mock_agent)
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new resource" do
      Resource.should_receive(:new).and_return(@resource)
      do_get
    end
  
    it "should not save the new resource" do
      @resource.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new resource for the view" do
      do_get
      assigns[:resource].should equal(@resource)
    end
  end

  describe "handling GET /resources/1/edit" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :agents => [@mock_agent])
      Resource.stub!(:find).and_return(@resource)
    end
  
    def do_get
      controller.stub!(:current_agent).and_return(@mock_agent)
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end
  
    it "should find the resource requested" do
      Resource.should_receive(:find).and_return(@resource)
      do_get
    end
  
    it "should assign the found Resource for the view" do
      do_get
      assigns[:resource].should equal(@resource)
    end
  end
  
  describe "handling GET /resources/1/edit" do
    before(:each) do
      controller.stub!(:is_user_admin?).and_return(false)
      @admin = mock_model(User)
      @admin.stub!(:is_admin?).and_return(false)
      @mock_agent = mock_model(Agent)
      @mock_agent.stub!(:ready_for_agreement?).and_return(true)
      @resource = mock_model(Resource)
      Resource.stub!(:find).and_return(@resource)
    end

    def do_get   
      controller.stub!(:current_agent).and_return(@mock_agent)
      get :edit, :id => @resource.id, :content_partner_id => @mock_agent.id
    end

    it "should get edit resource when resource associated with agent and not admin" do
      @resource.should_receive(:agents).and_return(@mock_agent)    
      @mock_agent.should_receive(:include?).and_return(true)
      do_get
      response.should be_success
    end
        
    it "should *not* edit resource when resource not associated with agent and not admin" do
      @resource.should_receive(:agents).and_return([])    
      do_get
      response.should_not be_success
    end
        
  end

  describe "handling GET /resources/1/edit AS admin" do
    before(:each) do
      controller.stub!(:is_user_admin?).and_return(true)
      @admin = mock_model(User)
      @admin.stub!(:is_admin?).and_return(true)
      @mock_agent = mock_model(Agent)
      @mock_agent.stub!(:ready_for_agreement?).and_return(true)      
      @resource = mock_model(Resource)
      Resource.stub!(:find).and_return(@resource)
    end

    def do_get
      controller.stub!(:current_agent).and_return(nil)
      get :edit, :id => @resource.id, :content_partner_id => @mock_agent.id
    end
    
    it "should get edit resource when admin" do
      do_get
      response.should be_success
    end
  end
    
  describe "handling POST /resources" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :to_param => "1", :agents => [@mock_agent], :dataset_file_name => 'filenamey.fil')
      Resource.stub!(:new).and_return(@resource)
    end
    
    describe "with successful save" do
  
      def do_post
        controller.stub!(:current_agent).and_return(@mock_agent)
        mock_attachment = mock_model(Hash) # class doesn't really matter here.
        mock_attachment.should_receive(:path).and_return("/some/path")
        @resource.should_receive(:save).at_least(1).times.and_return(true)
        @resource.should_receive(:dataset).and_return(mock_attachment)
        @resource.should_receive(:accesspoint_url).at_least(1).times.and_return('') # This will be tested for blank, and we would like it to be.
        @resource.should_receive(:resource_status=).at_least(1).times
        raise 'SORRY! (sez JRice) ...this was calling a web service and freezing on my system.  Fix this.'
        post :create, :resource => {}
      end
  
      it "should create a new resource" do
        Resource.should_receive(:new).with({}).and_return(@resource)
        do_post
      end

      it "should redirect to the new resource" do
        do_post
        response.should redirect_to(resources_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @resource.should_receive(:save).and_return(false)
        controller.stub!(:current_agent).and_return(@mock_agent)
        post :create, :resource => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /resources/1" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :to_param => "1", :agents => [@mock_agent])
      Resource.stub!(:find).and_return(@resource)
    end
    
    describe "with successful update" do

      def do_put
        @resource.should_receive(:update_attributes).and_return(true)
        @resource.should_receive(:save)
        controller.stub!(:current_agent).and_return(@mock_agent)
        put :update, :id => "1"
      end

      it "should find the resource requested" do
        Resource.should_receive(:find).with("1").and_return(@resource)
        do_put
      end

      it "should update the found resource" do
        do_put
        assigns(:resource).should equal(@resource)
      end

      it "should assign the found resource for the view" do
        do_put
        assigns(:resource).should equal(@resource)
      end

      it "should redirect to the resources" do
        do_put
        response.should redirect_to(resources_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @resource.should_receive(:update_attributes).and_return(false)
        controller.stub!(:current_agent).and_return(@mock_agent)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /resources/1" do

    before(:each) do
      @mock_agent = mock_agent_for_resource
      @resource = mock_model(Resource, :destroy => true, :agents => [@mock_agent])
      Resource.stub!(:find).and_return(@resource)
    end
  
    def do_delete
      controller.stub!(:current_agent).and_return(@mock_agent)
      delete :destroy, :id => "1"
    end

    it "should find the resource requested" do
      Resource.should_receive(:find).with("1").and_return(@resource)
      do_delete
    end
  
    it "should call destroy on the found resource" do
      @resource.should_receive(:destroy)
      request.env["HTTP_REFERER"] = 'whatever'
      do_delete
    end
  
    it "should redirect to the resources list" do
      do_delete
      response.should redirect_to(resources_url)
    end
  end
end
