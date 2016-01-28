require 'spec_helper'

describe 'taxa/overview/show' do

  before(:all) do
    Language.create_english
    UriType.create_enumerated
    Vetted.create_enumerated
    Visibility.create_enumerated
    License.create_enumerated
    ContentPartnerStatus.create_enumerated
  end

  before(:each) do
    # TODO - generalize these extends for the other view specs.
    taxon_concept = double(TaxonConcept)
    taxon_concept.stub(:id) { 1 }
    taxon_data = double(TaxonData, distinct_predicates: [])
    data = double(TaxonDataSet)
    data.stub(:categorize) { {} }
    data.stub(:count) { 0 }
    data.stub(:blank?) { true }
    overview = double(TaxonOverview)
    overview.stub(:taxon_concept) { taxon_concept }
    overview.stub(:media) { [] }
    overview.stub(:map?) { false }
    overview.stub(:iucn_status) { 'lucky' }
    overview.stub(:iucn_url) { 'http://iucn.org' }
    overview.stub(:summary?) { false }
    overview.stub(:details?) { false }
    overview.stub(:collections_count) { 0 }
    overview.stub(:communities_count) { 0 }
    overview.stub(:classification_filter?) { false }
    overview.stub(:classification_curated?) { false }
    overview.stub(:classifications_count) { 0 }
    overview.stub(:curators_count) { 0 }
    overview.stub(:hierarchy_entry) { nil } # This is a little dangerous, but it avoids rendinger the entire node partial..
    overview.stub(:activity_log) { [].paginate } # CHEAT!  :D
    taxon_page = double(TaxonPage, id: 123, scientific_name: 'Aus bus')
    taxon_page.stub(:data) { taxon_data }
    assign(:taxon_page, taxon_page)
    assign(:overview, double(TaxonOverview))
    assign(:overview_data, { })
    assign(:range_data, { })
    assign(:assistive_section_header, 'assist my overview')
    assign(:rel_canonical_href, 'some canonical stuff')
    assign(:overview, overview)
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_language) { Language.default }
    view.stub(:current_url) { 'http://yes.we/really_have/this-helper.method' }
  end

  context 'logged out' do

    before(:each) do
      user = EOL::AnonymousUser.new(Language.default)
      view.stub(:current_user) { user }
      view.stub(:logged_in?) { false }
    end

    it "should NOT show quick facts when the user doesn't have access (FOR NOW)" do
      render
      expect(rendered).to_not match /#{I18n.t(:data_summary_header_with_count, count: 0)}/
    end

  end

  context 'logged with see_data permission' do

    before(:each) do
      user = double(User)
      user.stub(:min_curator_level?) { false }
      user.stub(:watch_collection) { nil }
      user.stub(:logo_url) { 'whatever' }
      view.stub(:current_user) { user }
      view.stub(:logged_in?) { false }
    end

    it "should show quick facts" do
      point = DataPointUri.gen
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview){{ point => { data_point_uris: [ point ]} }}
      assign(:data, taxon_page)
      render
      expect(rendered).to match /#{I18n.t(:data_summary_header_with_count, count: 0)}/
    end

    it "should have a show more link when a row has more data" do
      point = DataPointUri.gen
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview){{ point => { data_point_uris: [ point ], show_more: true } }}
      assign(:data, taxon_page)
      render
      expect(rendered).to have_tag('td a', text: 'more')
    end

    it "should show statistical method" do
      point = DataPointUri.gen(statistical_method: 'Itsmethod')
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview) {{ point => { data_point_uris: [ point ] } }}
      assign(:data, taxon_page)
      render
      expect(rendered).to have_tag('span.stat', text: /Itsmethod/)
    end

    it "should show life stage" do
      point = DataPointUri.gen(life_stage: 'Itslifestage')
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview) {{ point => { data_point_uris: [ point ] } }}
      assign(:data, taxon_page)
      render
      expect(rendered).to have_tag('span.stat', text: /Itslifestage/)
    end

    it "should show sex" do
      point = DataPointUri.gen(sex: 'Itssex')
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview) {{ point => { data_point_uris: [ point ] } }}
      assign(:data, taxon_page)
      render
      expect(rendered).to have_tag('span.stat', text: /Itssex/)
    end

    it "should show combinations of context modifiers" do
      point = DataPointUri.gen(statistical_method: 'Itsmethod', life_stage: 'Itslifestage', sex: 'Itssex')
      taxon_page = double(TaxonPage)
      taxon_page.stub(:get_data_for_overview) {{ point => { data_point_uris: [ point ] } }}
      assign(:data, taxon_page)
      render
      expect(rendered).to have_tag('span.stat', text: /Itsmethod, Itslifestage, Itssex/)
    end

  end

end
