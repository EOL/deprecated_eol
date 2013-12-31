require 'spec_helper'

describe 'taxa/data/index' do

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
    @taxon_concept = double(TaxonConcept, id: 1)
    @taxon_concept.stub(:latest_version) { @taxon_concept }
    taxon_data = double(TaxonData, taxon_concept: @taxon_concept, bad_connection?: false)
    taxon_data.stub(:get_data) { [] }
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
    assign(:range_data, [])
    assign(:include_other_category, true)
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

  context 'with data' do

    # TODO - this is too much setup, and indicates that the view is doing too much work. I agree. Fix it.
    before(:each) do
      # TODO - all this FG nonsense could be condensed to a single FG factory. It's too much.
      @chucks = FactoryGirl.build(:known_uri_unit)
      tku = FactoryGirl.build(:translated_known_uri, name: 'chucks', known_uri: @chucks)
      taxon_concept = double(TaxonConcept, id: 1)
      taxon_concept.stub(:latest_version) { taxon_concept }
      dpu = DataPointUri.gen(unit_of_measure_known_uri: @chucks,
                             object: "2.354",
                             taxon_concept: taxon_concept,
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

    it "should show statistical method" do
      assign(:data_point_uris, [ DataPointUri.gen(predicate: 'Itspredicate', statistical_method: 'Itsmethod') ])
      render
      expect(rendered).to have_tag('span.stat', text: /Itsmethod/)
    end

    it "should show life stage" do
      assign(:data_point_uris, [ DataPointUri.gen(life_stage: 'Itslifestage') ])
      render
      expect(rendered).to have_tag('span.stat', text: /Itslifestage/)
    end

    it "should show sex" do
      assign(:data_point_uris, [ DataPointUri.gen(sex: 'Itssex') ])
      render
      expect(rendered).to have_tag('span.stat', text: /Itssex/)
    end

    it "should show sex and life stage together" do
      assign(:data_point_uris, [ DataPointUri.gen(life_stage: 'Itslifestage', sex: 'Itssex') ])
      render
      expect(rendered).to have_tag('span.stat', text: /Itslifestage, Itssex/)
    end

    context 'search' do

      it "should include attribute drop-down" do
        render
        expect(rendered).to have_tag('select#attribute')
      end

      # Nasty test, sorry. Method chains.  ...TODO - that's a bad smell; we should make the code clearer.
      it 'should include all attributes from the TaxonData' do
        taxon_data = double(TaxonData, taxon_concept: @taxon_concept, bad_connection?: false)
        kuri1 = double(KnownUri, name: 'Hi')
        kuri2 = double(KnownUri, name: 'There')
        kuri3 = double(KnownUri, name: 'Friend')
        pred1 = double(DataPointUri, predicate_uri: kuri1)
        pred2 = double(DataPointUri, predicate_uri: kuri2)
        pred3 = double(DataPointUri, predicate_uri: kuri3)
        taxon_data.stub(:get_data) { [pred1, pred2, pred3] }
        assign(:taxon_data, taxon_data)
        render
        expect(rendered).to have_tag('option', text: 'Hi')
        expect(rendered).to have_tag('option', text: 'There')
        expect(rendered).to have_tag('option', text: 'Friend')
      end

    end

  end

end
