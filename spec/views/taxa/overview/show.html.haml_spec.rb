require 'spec_helper'

describe 'taxa/overview/show' do

  before(:all) do
    Visibility.create_defaults
    Vetted.create_defaults
    CuratorLevel.create_defaults
    Language.create_english # :\
    @anonymous = EOL::AnonymousUser.new('en')
    @curator = FactoryGirl.create(:curator)
    @taxon = TaxonConcept.gen()
  end

  before(:each) do
    # TODO - generalize these extends for the other view specs.
    view.extend(ApplicationHelper)
    view.extend(TaxaHelper)
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    @data = double(TaxonDataSet)
    allow(@data).to receive(:categorize).and_return({})
    assigns[:taxon_page] = double(TaxonPage)
    assigns[:overview] = double(TaxonOverview)
    assigns[:data_point_uris] = @data
    assigns[:assistive_section_header] = 'assist my overview'
    assigns[:rel_canonical_href] = 'some canonical stuff'
  end


  context '(logged out)' do

    before(:each) do
      view.stub(:current_user).and_return(@anonymous)
      assigns[:overview] = TaxonOverview.new(@taxon_page, @anonymous)
    end

    it 'should NOT show the key' do
      render
      expect(rendered).to include(I18n.t(:data_tab_curator_key_exemplar, image: ""))
    end

  end

end
