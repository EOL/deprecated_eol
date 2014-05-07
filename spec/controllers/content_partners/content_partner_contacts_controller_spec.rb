require File.dirname(__FILE__) + '/../../spec_helper'

describe ContentPartners::ContentPartnerContactsController do

  # This is a little weird, but we have some cases where an access_denied is expected to call
  # redirect_back_or_default and if it doesn't, it will bail out on another problem. This allows us to control how
  # that works:
  class Redirection < StandardError ; end

  before(:all) do
    Language.create_english
    ContentPartnerStatus.create_enumerated
  end

  let(:content_partner) { ContentPartner.gen(full_name: 'Test content partner') }

  before do
    allow(controller).to receive(:check_authentication) { false }
    @user = build_stubbed(User)
    allow(@user).to receive(:can_create?) { true }
    allow(controller).to receive(:current_user) { @user }
  end

  describe 'GET new' do

    it 'checks authentication' do
      get :new, content_partner_id: content_partner.id
      expect(controller).to have_received(:check_authentication)
    end

    it 'assigns partner' do
      get :new, content_partner_id: content_partner.id
      expect(assigns(:partner)).to eq(content_partner)
    end

    it 'assigns contract' do
      get :new, content_partner_id: content_partner.id
      expect(assigns(:contact)).to be_a(ContentPartnerContact)
    end

    it 'denies access if user cannot create contact' do
      allow(controller).to receive(:access_denied) { 200 }
      allow(@user).to receive(:can_create?) { false }
      get :new, content_partner_id: content_partner.id
      expect(controller).to have_received(:access_denied)
    end

    it 'assigns new page_subheader' do
      get :new, content_partner_id: content_partner.id
      expect(assigns(:page_subheader)).to eq(I18n.t(:content_partner_contact_new_page_subheader))
    end

  end

  describe 'POST create' do

    it 'checks authentication' do
      post :create, content_partner_contact: {}, content_partner_id: content_partner.id
      expect(controller).to have_received(:check_authentication)
    end

    it 'assigns partner' do
      post :create, content_partner_contact: {}, content_partner_id: content_partner.id
      expect(assigns(:partner)).to eq(content_partner)
    end

    it 'assigns contract' do
      post :create, content_partner_contact: {}, content_partner_id: content_partner.id
      expect(assigns(:contact)).to be_a(ContentPartnerContact)
    end

    it 'denies access if user cannot create contact' do
      allow(controller).to receive(:access_denied) { raise Redirection }
      allow(@user).to receive(:can_create?) { false }
      expect do
        post(:create, content_partner_contact: {}, content_partner_id: content_partner.id)
      end.to raise_error(Redirection)
    end

    context 'with a proper contact' do

      subject do
        post :create,
          content_partner_contact: build(ContentPartnerContact, content_partner: content_partner).attributes,
          content_partner_id: content_partner.id
      end

      it 'tells you it worked' do
        subject # Well, this is lame ... but it doesn't run without this line!
        expect(flash[:notice]).to eq(I18n.t(:content_partner_contact_create_successful_notice))
      end

      it 'redirects to content partner' do
        expect(subject).to redirect_to(content_partner_resources_path(content_partner))
      end

    end

    context 'with an INVALID contact' do

      subject do
        post :create,
          content_partner_contact: {},
          content_partner_id: content_partner.id
      end

      it 'tells you it failed' do
        subject # Well, this is lame ... but it doesn't run without this line!
        expect(flash.now[:error]).to eq(I18n.t(:content_partner_contact_create_unsuccessful_error))
      end

      it 'renders :new' do
        expect(subject).to render_template(:new)
      end

      it 'assigns new page_subheader' do
        subject # Sigh.
        expect(assigns(:page_subheader)).to eq(I18n.t(:content_partner_contact_new_page_subheader))
      end

    end

  end

  it 'will test all the edit stuff'

  it 'will test all the update stuff'

  it 'will test all the delete stuff'

end
