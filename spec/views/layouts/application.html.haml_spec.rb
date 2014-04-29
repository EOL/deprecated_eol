require 'spec_helper'

describe 'layouts/application' do

  before(:all) do
    Language.create_english
    @user = EOL::AnonymousUser.new(Language.default)
  end

  before(:each) do
    view.stub(:current_user) { @user }
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
    view.stub(:current_url) { 'yey' }
    view.stub(:meta_data) { { title: 'The title' } }
  end

  context 'with results' do

    before do
      allow(EolConfig).to receive(:banner_i18n_key).and_raise(ActiveRecord::RecordNotFound)
    end

    subject { render ; rendered }

    it { should have_tag('input[name=search]') }
    it { should have_tag('#banner') }
    # NOTE - this tests that the EolConfig.banner_i18n_key uses a default:
    it { should match(I18n.t(:traitbank_banner)) }

    it 'calls banner_i18n_key' do
      subject
      expect(EolConfig).to have_received(:banner_i18n_key)
    end

  end

end
