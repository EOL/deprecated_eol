require File.dirname(__FILE__) + '/../../spec_helper'

def log_in_for_controller(controller, user)
  session[:user_id] = user.id
  controller.set_current_user = user
end

describe ContentPartners::ResourcesController do

  before(:all) do
    unless @user = User.find_by_username('partner_resources_controller')
      truncate_all_tables
      Language.create_english
      CuratorLevel.create_enumerated
      ContentPartnerStatus.create_enumerated
      License.create_enumerated
      UserIdentity.create_enumerated
      @user = User.gen(:username => 'partner_resources_controller')
    end
    @content_partner = ContentPartner.gen(:user => @user, :full_name => 'Test content partner')
    @content_partner_contact = ContentPartnerContact.gen(:content_partner => @content_partner)
    @resource = Resource.gen(:content_partner => @content_partner)
  end

  describe 'GET index' do
    it 'should render root if user not logged in' do
      get :index, { :content_partner_id => @content_partner.id }
      expect(response).to redirect_to(login_url)
    end
    it 'should ask for agreement if user can update content partner and agreement is NOT accepted' do
      ContentPartnerAgreement.delete_all
      log_in_for_controller(controller, @user)
      get :index, { :content_partner_id => @content_partner.id }
      response.should redirect_to(new_content_partner_agreement_path(@content_partner))
    end
    it 'should render index if user can update content partner and agreement is accepted' do
      @content_partner_agreement = ContentPartnerAgreement.gen(:content_partner => @content_partner, :signed_on_date => Time.now)
      log_in_for_controller(controller, @user)
      get :index, { :content_partner_id => @content_partner.id }
      # not working, we're redirected and not following it...
      assigns[:partner].should == @content_partner
      assigns[:resources].should be_a(Array)
      assigns[:resources].first.should == @resource
      assigns[:partner_contacts].should be_a(Array)
      assigns[:partner_contacts].first.should == @content_partner_contact
      response.status.should == 200
      response.should render_template('content_partners/resources/index')
    end
  end

  describe 'GET new' do
    it 'should render new only if user can create content partner resources' do
      get :new, { :content_partner_id => @content_partner.id }
      response.should_not render_template('content_partners/resources/new')
      expect(response).to redirect_to(login_url)
      # Really need to have at least one license to show:
      License.last.update_attributes(show_to_content_partners: 1)
      get :new, { :content_partner_id => @content_partner.id }, { :user => @user, :user_id => @user.id }
      response.should render_template('content_partners/resources/new')
      response.status.should == 200
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
      expect(response).to redirect_to(login_url)
      get :edit, { :content_partner_id => @content_partner.id, :id => @resource.id }, { :user => @user, :user_id => @user.id }
      assigns[:partner].should == @content_partner
      assigns[:resource].should == @resource
      response.should render_template('content_partners/resources/edit')
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
      expect(response).to redirect_to(login_url)
    end
    it 'should render resource show page if user can read content partner resources' do
      log_in_for_controller(controller, @user)
      get :show, { :content_partner_id => @content_partner.id, :id => @resource.id }, { :user => @user, :user_id => @user.id }
      assigns[:partner].should == @content_partner
      assigns[:resource].should == @resource
      response.should render_template('content_partners/resources/show')
    end
    it "shows the resource page even if the partner's id is missing" do
      log_in_for_controller(controller, @user)
      get :show, { id: @resource.id }, {user: @user, user_id: @user.id}
      expect(response).to render_template('content_partners/resources/show')
      expect(assigns[:partner]).to eq(@content_partner)
      expect(assigns[:resource]).to eq(@resource)
    end
  end
  
  describe 'DELETE destroy' do
    
    before(:all) do
      @resource_for_deletion = Resource.gen(:content_partner => @content_partner)
    end
    
    context 'when user can delete resource' do #admin
      
      before(:all) do
        @admin = User.gen
        @admin.grant_admin
      end
      
      it "should call destroy all harvest events related to this resource" do
        log_in_for_controller(controller, @admin)
        delete :destroy, { :content_partner_id => @content_partner.id, :id => @resource_for_deletion.id }
        expect(@resource_for_deletion.harvest_events).to be_blank
        expect(response).to redirect_to(content_partner_path(@content_partner))
        expect(flash[:notice]).to eq(I18n.t(:content_partner_resource_will_be_deleted, resource_title: @resource_for_deletion.title))
      end
    end
    
    context 'when user can not delete resource' do # non admins
      it "should raise 'restricted to admin' exception" do
        log_in_for_controller(controller, @user)
        expect { delete :destroy, { :content_partner_id => @content_partner.id, :id => @resource_for_deletion.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
      end
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
