require 'spec_helper'

describe 'layouts/v2/data_search' do

  before(:all) do
    Language.create_english
    @user = EOL::AnonymousUser.new(Language.default)
  end

  before(:each) do
    view.stub(:current_user) { @user }
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
    view.stub(:current_url) { 'yey' }
  end

  context 'with results' do

    before(:each) do
      results = double(WillPaginate, total_entries: 12, blank?: false)
      assign(:results, results)
      assign(:attribute, 'attributed')
      assign(:querystring, 'queried')
      assign(:params, {})
      assign(:select_options, [['attributed', 1]])
      assign(:wildcard_search, false)
      assign(:meta_data, {title: 'titular'})
    end

    it "should include a drop-down with all attributes" do
      render
      expect(rendered).to have_tag('select#attribute')
    end

  end

end
