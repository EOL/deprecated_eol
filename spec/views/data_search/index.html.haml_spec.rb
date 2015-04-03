require "spec_helper"

describe 'data_search/index' do

  before(:all) do
    Language.create_english
    Visibility.create_enumerated
    DataType.create_enumerated
    @user = EOL::AnonymousUser.new(Language.default)
  end

  before(:each) do
    view.stub(:current_user) { @user }
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
  end

  context 'with no results' do

    context 'when server unavailable' do

      it 'should have a warning' do
        render
        expect(rendered).to have_content I18n.t(:data_server_unavailable)
      end

    end

  end

  context 'with results' do

    before(:each) do
      tc = build_stubbed(TaxonConcept)
      tc.stub(:latest_version).and_return(tc)
      kuri = create(TranslatedKnownUri, name: "Coolest Name Ever").known_uri # Need to save this for translation to work.  :|
      @result = build_stubbed(Trait, taxon_concept: tc, predicate_known_uri: kuri,
                  object: 'result1',  visibility: Visibility.visible)
      @hidden = build_stubbed(Trait, taxon_concept: tc, predicate_known_uri: kuri,
                  object: 'hidden result', visibility: Visibility.invisible)
      results = [@result, @hidden].paginate
      assign(:results, results)
    end

    it 'shows a row' do
      render
      expect(rendered).to match(@result.object)
    end

    it 'uses a placeholder when a row is hidden' do
      render
      expect(rendered).to match(I18n.t(:data_search_row_hidden))
      expect(rendered).to_not match(@hidden.object)
    end
    
    it 'shows the definition of the attribute'

    it 'starts with result 1'

    it 'ends with the last result number'

    context 'when paginated' do
      it 'has the right start number'
      it 'has the right end number'
    end

  end

end
