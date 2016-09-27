require "spec_helper"

describe PendingHarvestsController do

  before(:all) do
    CuratorLevel.create_enumerated
    ContentPartnerStatus.create_enumerated
    ResourceStatus.create_enumerated
    @admin = User.gen(admin: true)
    @full = FactoryGirl.create(:curator)
    @master = FactoryGirl.create(:master_curator)
    @content_partner = ContentPartner.gen(user: User.gen, content_partner_status: ContentPartnerStatus.active)
    @lang = Language.gen
    @license = License.gen
    res = Resource.gen(license_id: @license.id, language_id: @lang.id, content_partner: @content_partner, resource_status_id: ResourceStatus.processed.id)
  end

  describe 'GET index' do
    context 'grant access for admins and master curators'do
      it 'should work for admins' do
        session[:user_id] = @admin.id
        expect { get :index }.not_to raise_error
      end

      it 'should work for master curators' do
        session[:user_id] = @master.id
        expect { get :index }.not_to raise_error
      end
    end

    context 'deny access for other users' do
      it 'should deny access for full curators' do
        session[:user_id] = @full.id
        expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
      end

      it 'should deny access normal user' do
        session[:user_id] = User.gen.id
        expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
      end

      it 'should deny access for non-logged-in user' do
        session[:user_id] = nil
        expect { get :index }.to raise_error(EOL::Exceptions::SecurityViolation)
      end
    end

    context 'check on ready (pending) resources' do
      it 'should get the ready resources only' do
        res = Resource.gen(license_id: @license.id, language_id: @lang.id, content_partner: @content_partner, resource_status_id: ResourceStatus.harvest_requested.id)
        expect(Resource.ready.size).to eq(1)
      end
    end
  end
end
