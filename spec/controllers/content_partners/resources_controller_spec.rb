require File.dirname(__FILE__) + '/../../spec_helper'

describe ContentPartners::ResourcesController do

  before(:all) do
    unless @user = User.find_by_username('partner_resources_controller')
      truncate_all_tables
      Language.create_english
      CuratorLevel.create_defaults
      UserIdentity.create_defaults
      @user = User.gen(:username => 'partner_resources_controller')
    end
    @content_partner = ContentPartner.gen(:user => @user, :full_name => 'Test content partner')
    @content_partner_contact = ContentPartnerContact.gen(:content_partner => @content_partner)
    @resource = Resource.gen(:content_partner => @content_partner)
  end

  describe 'GET index' do
    it 'should render root if user not logged in' do
      get :index, { :content_partner_id => @content_partner.id }
      response.redirected_to.should == root_url
    end
    it 'should ask for agreement if user can update content partner and agreement is NOT accepted' do
      session[:user_id] = @user.id
      get :index, { :content_partner_id => @content_partner.id }
      response.redirected_to.should == new_content_partner_content_partner_agreement_path(@content_partner)
    end
    it 'should render index if user can update content partner and agreement is accepted' do
      @content_partner_agreement = ContentPartnerAgreement.gen(:content_partner => @content_partner, :signed_on_date => Time.now)
      session[:user_id] = @user.id
      get :index, { :content_partner_id => @content_partner.id }
      assigns[:partner].should == @content_partner
      assigns[:resources].should be_a(Array)
      assigns[:resources].first.should == @resource
      assigns[:partner_contacts].should be_a(Array)
      assigns[:partner_contacts].first.should == @content_partner_contact
      response.redirected_to.should be_blank
      response.rendered[:template].should == 'content_partners/resources/index.html.haml'
    end
  end

  describe 'GET new' do
    it 'should render new only if user can create content partner resources' do
      get :new, { :content_partner_id => @content_partner.id }
      response.rendered[:template].should_not == 'content_partners/resources/new.html.haml'
      response.redirected_to.should == login_url
      get :new, { :content_partner_id => @content_partner.id }, { :user => @user, :user_id => @user.id }
      response.rendered[:template].should == 'content_partners/resources/new.html.haml'
      response.redirected_to.should be_blank
    end
  end

#  describe 'POST create' do
#    it 'should create resource only if user can create content partner resources'
#    it 'should rerender new on validation errors'
#    it 'should redirect to content partner resources index on success'
#    it 'should upload resource to server'
#  end

  describe 'GET edit' do
    it 'should render edit only if user can update this content partner resource' do
      get :edit, { :content_partner_id => @content_partner.id, :id => @resource.id }
      response.redirected_to.should == login_url
      get :edit, { :content_partner_id => @content_partner.id, :id => @resource.id }, { :user => @user, :user_id => @user.id }
      assigns[:partner].should == @content_partner
      assigns[:resource].should == @resource
      response.rendered[:template].should == 'content_partners/resources/edit.html.haml'
    end
  end

#  describe 'PUT update' do
#    it 'should update resource only if user can update this content partner resource'
#    it 'should rerender edit on validation errors'
#    it 'should redirect to content partner resources index on success'
#  end

  describe 'GET show' do
    it 'should render root if user not logged in' do
      get :show, { :content_partner_id => @content_partner.id, :id => @resource.id }
      response.redirected_to.should == root_url
    end
    it 'should render resource show page if user can read content partner resources' do
      session[:user_id] = @user.id
      get :show, { :content_partner_id => @content_partner.id, :id => @resource.id }, { :user => @user, :user_id => @user.id }
      assigns[:partner].should == @content_partner
      assigns[:resource].should == @resource
      response.rendered[:template].should == 'content_partners/resources/show.html.haml'
    end
  end

#  describe 'GET and POST force_harvest' do
#    it 'should change resource status to force harvest only if user can update resource and state transition is allowed'
#    it 'should redirect back or default on success'
#  end
#
#  describe 'POST publish' do
#    it 'should change resource status to publish pending only if user is EOL administrator and state transition is allowed'
#    it 'should redirect back or default on success'
#  end

end
