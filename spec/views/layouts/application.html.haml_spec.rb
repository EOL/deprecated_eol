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

    before(:each) do
      # Later
    end

    it "should include search" do
      render
      expect(rendered).to have_tag('input[name=search]')
    end

  end

end
