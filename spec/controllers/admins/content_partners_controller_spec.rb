require File.dirname(__FILE__) + '/../../spec_helper'

describe Admins::ContentPartnersController do
  describe 'GET index' do
    before(:all) do
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
      @non_admin = User.find_by_admin(false)
      @cp_all_unpublished = ContentPartner.gen(:user => @non_admin)
      resource = Resource.gen(:content_partner_id => @cp_all_unpublished.id)
      HarvestEvent.gen(:resource_id => resource.id, :published_at => nil)
      HarvestEvent.gen(:resource_id => resource.id, :published_at => nil)
      @cp_latest_unpublished = ContentPartner.gen(:user => @non_admin)
      resource = Resource.gen(:content_partner_id => @cp_latest_unpublished.id)
      HarvestEvent.gen(:resource_id => resource.id)
      HarvestEvent.gen(:resource_id => resource.id, :published_at => nil)
      @partners ||= ContentPartner.all(:order => 'content_partners.full_name')
      @cp_latest_published ||= @partners.select{|cp| cp.full_name == 'IUCN'}.first
      @cp_no_harvests ||= @partners.select{|cp| cp.full_name == 'Biology of Aging'}.first
      @cp_no_resources ||= @partners.select{|cp| cp.full_name == 'Catalogue of Life'}.first
    end
    
    it 'should only allow access to EOL administrators' do
      get :index
      expect(response).to redirect_to(login_url)
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate content partners with default sort by partner name' do
      get :index, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == @partners
      response.status.should == 200
      response.should render_template("admins/content_partners/index")
    end
    it 'should filter by name' do
      get :index, {:name => @cp_latest_published.full_name}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_published]
    end
    it 'should filter by never harvested' do
      get :index, {:published => '0'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_no_harvests, @cp_no_resources].sort_by{|cp| cp.full_name}
    end
    it 'should filter by never published' do
      get :index, {:published => '1'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_all_unpublished, @cp_no_resources, @cp_no_harvests].sort_by{|cp| cp.full_name}
    end
    it 'should filter by latest harvest events that are unpublished' do
      get :index, {:published => '2'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_unpublished, @cp_all_unpublished].sort_by{|cp| cp.full_name}
    end
    it 'should filter by latest harvest events that are pending publish' do
      he = @cp_latest_unpublished.resources.first.harvest_events.last
      he.update_column(:publish, true)
      get :index, {:published => '3'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_unpublished]
      he.update_column(:publish, false)
    end
    it 'should filter by latest harvest events that are published' do
      get :index, {:published => '4'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_published]
    end
    it 'should filter by partners that have no resources' do
      get :index, {:published => '5'}, { :user => @admin, :user_id => @admin.id }
      expect(assigns[:partners]).to include(@cp_no_resources)
      expect(assigns[:partners]).not_to include(@cp_latest_published)
    end
  end

  describe 'GET notifications' do
    before(:all) do
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
      @non_admin = User.find_by_admin(false)
    end
    
    it 'should only allow access to EOL administrators' do
      get :notifications
      expect(response).to redirect_to(login_url)
      expect{ get :notifications, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render notifications view' do
      get :notifications, nil, { :user => @admin, :user_id => @admin.id }
      response.should render_template("admins/content_partners/notifications")
    end
  end

  describe 'POST notifications' do
    before(:all) do
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
      @non_admin = User.find_by_admin(false)
    end
    
    it 'should only allow access to EOL administrators' do
      post :notifications, { :notification => 'content_partner_statistics_reminder' }
      expect(response).to redirect_to(login_url)
      expect{ post :notifications, { :notification => 'content_partner_statistics_reminder' },
                                   { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it "should send statistics reminder notification" do
      contact = ContentPartnerContact.first(:include => { :content_partner => :user })
      last_month = Date.today - 1.month
      GoogleAnalyticsPartnerSummary.gen(:year => last_month.year, :month => last_month.month, :user => contact.content_partner.user)
      mailer = double
      mailer.should_receive(:deliver)
      Notifier.should_receive(:content_partner_statistics_reminder).with(contact.content_partner, contact, Date::MONTHNAMES[last_month.month], last_month.year).
        and_return(mailer)
      post :notifications, { :notification => 'content_partner_statistics_reminder' }, { :user => @admin, :user_id => @admin.id }
    end
  end

  describe 'GET statistics' do
    before(:all) do
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
      @non_admin = User.find_by_admin(false)
    end
    
    it 'should only allow access to EOL administrators' do
      get :statistics
      expect(response).to redirect_to(login_url)
      expect{ get :statistics, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render statistics view' do
      get :statistics, nil, { :user => @admin, :user_id => @admin.id }
      response.should render_template("admins/content_partners/statistics")
    end
    it 'should filter content partners on first published date' do
      cp = ContentPartner.gen(:user => @non_admin)
      r = Resource.gen(:content_partner_id => cp.id)
      he = HarvestEvent.gen(:resource_id => r.id, :published_at => Time.mktime(2000, 01, 15),
               :began_at => Time.mktime(2000, 01, 14), :completed_at => Time.mktime(2000, 01, 14))
      from = { :year => 2000, :month => 01, :day => 14 }
      to = { :year => 2000, :month => 01, :day => 16 }
      get :statistics, { :from => from, :to =>  to }, { :user => @admin, :user_id => @admin.id }
      assigns[:harvest_events].should == [he]
    end
  end

end
