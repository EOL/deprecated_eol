require "spec_helper"

describe 'taxa/data/index' do

  def assign_nothing
    assign(:assistive_section_header, 'whatever')
    assign(:recently_used, nil)
    assign(:taxon_page, @taxon_page)
    assign(:taxon_data, @taxon_page.data)
    @data = TaxonDataSet.new([])
    @data.stub(:empty?).and_return(false)
    assign(:traits, @data)
    assign(:toc_id, nil)
    assign(:selected_trait_id, nil)
    assign(:categories, TocItem.for_uris(Language.english).select{ |toc| @taxon_page.data.categories.include?(toc) })
    assign(:toc_id, nil)
    assign(:supress_disclaimer, true)
    assign(:range_data, [])
    assign(:glossary_terms, [])
    assign(:units_for_select, KnownUri.default_units_for_form_select)
  end

  before(:all) do
    load_foundation_cache
    Visibility.create_enumerated
    Vetted.create_enumerated
    CuratorLevel.create_enumerated
    KnownUri.create_enumerated
    UriType.create_enumerated
    License.create_enumerated
    ContentPartnerStatus.create_enumerated
    Language.create_english # :\
    @anonymous = EOL::AnonymousUser.new('en')
    @curator = FactoryGirl.create(:curator)
    @taxon = TaxonConcept.gen()
  end

  before(:each) do
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
  end

  describe '(logged out)' do

    before(:each) do
      @taxon_page = TaxonUserClassificationFilter.new(@taxon, @anonymous)
      view.stub(:current_user).and_return(@anonymous)
      assign_nothing
    end

    it 'should NOT show the key' do
      render
      expect(rendered).not_to include(I18n.t(:data_tab_curator_key_exemplar, image: "", link: taxon_overview_path(@taxon_page)))
    end

  end

  describe '(as a full curator)' do

    before(:each) do
      @taxon_page = TaxonUserClassificationFilter.new(@taxon, @curator)
      view.stub(:current_user).and_return(@curator)
      assign_nothing
    end

    it 'should show the key' do
      render
      expect(rendered).to include(I18n.t(:data_tab_curator_key_exemplar, image: "", link: taxon_overview_path(@taxon_page)))
    end

  end

  context 'logged in' do

    before(:each) do
      taxon_concept = build_stubbed(TaxonConcept)
      taxon_concept.stub(:latest_version) { taxon_concept }
      taxon_data = double(TaxonData, taxon_concept: taxon_concept, bad_connection?: false)
      taxon_data.stub(:get_data) { [] }
      taxon_page = double(TaxonPage)
      taxon_page.stub(:scientific_name) { 'Arspecius viewicaa' }
      taxon_page.stub(:id) { 1 }
      assign(:taxon_page, taxon_page)
      assign(:taxon_data, taxon_data)
      assign(:toc_id, nil)
      assign(:selected_trait_id, nil)
      assign(:supress_disclaimer, true) # I don't even know what this is.  remove it?
      assign(:assistive_section_header, 'assist my taxon_data')
      assign(:categories, [])
      assign(:glossary_terms, [])
      assign(:range_data, [])
      assign(:include_other_category, true)
      assign(:units_for_select, KnownUri.default_units_for_form_select)
      user = build_stubbed(User)
      user.stub(:can_see_data?) { true }
      view.stub(:current_user) { user }
      view.stub(:current_language) { Language.default }
      view.stub(:logged_in?) { false }
      view.stub(:clade_searchable?) { true }
      @ku = FactoryGirl.build(:known_uri_unit)
      FactoryGirl.build(:translated_known_uri, name: 'chucks', known_uri: @ku)
      @tc = TaxonConcept.gen
    end

    context "without traits" do
      before :each do
        dpu_min = Trait.gen(unit_of_measure_known_uri: @ku,
                                object: "10",
                                taxon_concept: @tc,
                                vetted: Vetted.trusted,
                                visibility: Visibility.visible)
        dpu_max = Trait.gen(unit_of_measure_known_uri: @ku,
                                object: "100",
                                taxon_concept: @tc,
                                vetted: Vetted.trusted,
                                visibility: Visibility.visible)
        dpu_min.reload
        dpu_max.reload
        ranges = {attribute: @ku, min: dpu_min, max: dpu_max}
        assign(:range_data, [ranges])
        assign(:traits, [])
      end
      it "go to data_summaries subtab by default" do
        render
        expect(rendered).to have_tag('h3', text: /Data summaries/)
      end
    end

    context 'with data' do
      before(:each) do
        @dpu = Trait.gen(unit_of_measure_known_uri: @ku,
                              object: ".354",
                              taxon_concept: @tc,
                              vetted: Vetted.trusted,
                              visibility: Visibility.visible)

        curator = User.gen(curator_level_id: 1, curator_approved: 1, :credentials => 'Blah', :curator_scope => 'More blah')
        session[:user_id] = curator.id
        allow(controller).to receive(:current_user) { curator }
        @comment = Comment.gen(parent_id: @dpu.id, parent_type: "Trait", body: "This is a comment")
        @dpu.reload
        assign(:traits, [@dpu])
      end

      it "should NOT show units when undefined" do
        render
        expect(rendered).to_not have_tag('span', text: /chucks/)
      end

      it "should show units when defined" do
        EOL::Sparql.should_receive(:explicit_measurement_uri_components).with(@ku).and_return(DataValue.new('chucks'))
        render
        expect(rendered).to have_tag('span', text: /chucks/)
      end

      it "should show statistical method" do
        assign(:traits, [ Trait.gen(predicate: 'Itspredicate', statistical_method: 'Itsmethod') ])
        render
        expect(rendered).to have_tag('span.stat', text: /Itsmethod/)
      end

      it "should show life stage" do
        assign(:traits, [ Trait.gen(life_stage: 'Itslifestage') ])
        render
        expect(rendered).to have_tag('span.stat', text: /Itslifestage/)
      end

      it "should show sex" do
        assign(:traits, [ Trait.gen(sex: 'Itssex') ])
        render
        expect(rendered).to have_tag('span.stat', text: /Itssex/)
      end

      it "should show sex and life stage together" do
        assign(:traits, [ Trait.gen(life_stage: 'Itslifestage', sex: 'Itssex') ])
        render
        expect(rendered).to have_tag('span.stat', text: /Itslifestage, Itssex/)
      end

      it "displays the comment" do
        render
        expect(rendered).to include("#{@comment.body}")
      end

      it "displays date of comment" do
        render
        expect(rendered).to have_tag('small', text: /ago/)
      end
    end
  end
end
