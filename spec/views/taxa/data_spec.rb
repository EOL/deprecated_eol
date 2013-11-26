require 'spec_helper'

describe 'taxa/data/index' do

  before(:all) do
    Language.create_english
    UriType.create_defaults
    Vetted.create_defaults
    Visibility.create_defaults
  end

  before(:each) do
    # TODO - generalize these extends for the other view specs.
    taxon_concept = double(TaxonConcept)
    taxon_concept.stub(:id) { 1 }
    taxon_data = double(TaxonData)
    taxon_data.stub(:taxon_concept) { taxon_concept }
    taxon_data.stub(:bad_connection?) { false }
    taxon_page = double(TaxonPage)
    taxon_page.stub(:scientific_name) { 'Arspecius viewicaa' }
    assign(:taxon_page, taxon_page)
    assign(:taxon_data, taxon_data)
    assign(:toc_id, nil)
    assign(:selected_data_point_uri_id, nil)
    assign(:supress_disclaimer, true) # I don't even know what this is.  remove it?
    assign(:assistive_section_header, 'assist my taxon_data')
    assign(:categories, [])
    assign(:data_point_uris, [])
    assign(:glossary_terms, [])
    user = double(User)
    user.stub(:min_curator_level?) { false }
    user.stub(:watch_collection) { nil }
    user.stub(:can_see_data?) { true }
    user.stub(:can_update?) { false } # This user won't own anything.
    user.stub(:is_admin?) { false }
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_user) { user }
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
  end

  context 'when the data is empty' do

  end

  context 'with data' do

    # TODO - this is too much setup, and indicates that the view is doing too much work. I agree. Fix it.
    before(:each) do
      # TODO - all this FG nonsense could be condensed to a single FG factory. It's too much.
      @chucks = FactoryGirl.build(:known_uri_unit)
      tku = FactoryGirl.build(:translated_known_uri, name: 'chucks', known_uri: @chucks)
      dpu = DataPointUri.gen(unit_of_measure_known_uri: @chucks,
                             object: "2.354",
                             taxon_concept_id: 1, # Doesn't matter, but this matches above
                             vetted: Vetted.trusted,
                             visibility: Visibility.visible)
      assign(:data_point_uris, [dpu])
    end

    it "should NOT show units when undefined" do
      render
      expect(rendered).to_not have_tag('span', text: /chucks/)
    end

    it "should show units when defined" do
      EOL::Sparql.should_receive(:explicit_measurement_uri_components).with(@chucks).and_return(DataValue.new('chucks'))
      render
      expect(rendered).to have_tag('span', text: /chucks/)
    end

  end

end
