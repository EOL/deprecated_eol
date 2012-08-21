require File.dirname(__FILE__) + '/../../spec_helper'

describe Admins::ContentPartnersController do

  before(:all) do
    unless @admin = User.find_by_username('admins_controller_specs')
      truncate_all_tables
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
    end
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

  describe 'GET index' do
    it 'should only allow access to EOL administrators' do
      get :index
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate content partners with default sort by partner name' do
      get :index, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == @partners
      response.redirected_to.should be_nil
      response.rendered[:template].should == "admins/content_partners/index.html.haml"
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
      he = @cp_latest_unpublished.resources.first.latest_harvest_event
      he.update_attributes(:publish => true)
      get :index, {:published => '3'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_unpublished]
      he.update_attributes(:publish => false)
    end
    it 'should filter by latest harvest events that are published' do
      get :index, {:published => '4'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_latest_published]
    end
    it 'should filter by partners that have no resources' do
      get :index, {:published => '5'}, { :user => @admin, :user_id => @admin.id }
      assigns[:partners].should == [@cp_no_resources]
    end
  end

  describe 'GET notifications' do
    it 'should only allow access to EOL administrators' do
      get :notifications
      response.redirected_to.should == login_url
      expect{ get :notifications, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render notifications view' do
      get :notifications, nil, { :user => @admin, :user_id => @admin.id }
      response.rendered[:template].should == "admins/content_partners/notifications.html.haml"
    end
  end

  describe 'POST notifications' do
    it 'should only allow access to EOL administrators' do
      post :notifications, { :notification => 'content_partner_statistics_reminder' }
      response.redirected_to.should == login_url
      expect{ post :notifications, { :notification => 'content_partner_statistics_reminder' },
                                   { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it "should send statistics reminder notification" do
      contact = ContentPartnerContact.first(:include => { :content_partner => :user })
      last_month = Date.today - 1.month
      GoogleAnalyticsPartnerSummary.gen(:year => last_month.year, :month => last_month.month, :user => contact.content_partner.user)
      Notifier.should_receive(:deliver_content_partner_statistics_reminder).with(contact.content_partner, contact, Date::MONTHNAMES[last_month.month], last_month.year)
      post :notifications, { :notification => 'content_partner_statistics_reminder' }, { :user => @admin, :user_id => @admin.id }
    end
  end

  describe 'GET statistics' do
    it 'should only allow access to EOL administrators' do
      get :statistics
      response.redirected_to.should == login_url
      expect{ get :statistics, nil, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should render statistics view' do
      get :statistics, nil, { :user => @admin, :user_id => @admin.id }
      response.rendered[:template].should == "admins/content_partners/statistics.html.haml"
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