require 'spec_helper'

describe 'taxa/overview/show' do

  before(:all) do
    Language.create_english
  end

  before(:each) do
    # TODO - generalize these extends for the other view specs.
    view.extend(ApplicationHelper)
    view.extend(TaxaHelper)
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    taxon_concept = double(TaxonConcept)
    taxon_concept.stub(:id) { 1 }
    data = double(TaxonDataSet)
    data.stub(:categorize) { {} }
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
    assign(:taxon_page, double(TaxonPage))
    assign(:overview, double(TaxonOverview))
    assign(:data_point_uris, data)
    assign(:assistive_section_header, 'assist my overview')
    assign(:rel_canonical_href, 'some canonical stuff')
    assign(:overview, overview)
    view.stub(:current_language) { Language.default }
    view.stub(:current_url) { 'http://yes.we/really_have/this-helper.method' }
  end

  context '(logged out)' do

    before(:each) do
      user = EOL::AnonymousUser.new(Language.default)
      view.stub(:current_user) { user }
      view.stub(:logged_in?) { false }
    end

    it 'should do something' do
      render
      expect(true).to be_true
    end

  end

end
