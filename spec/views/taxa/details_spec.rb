require 'spec_helper'

describe 'taxa/details/index' do

  before(:all) do
    Language.create_english
    Vetted.create_enumerated
    Visibility.create_enumerated
    DataType.create_enumerated
    License.create_enumerated
    @article = DataObject.gen(description: 'article copy unlinked',
                              description_linked: 'article copy linked',
                              data_type: DataType.text,
                              source_url: 'http://sourcy.com')
  end

  # Yes. Yes, there is a LOT involved in showing articles, so there is a lot of setup. I prefer this to a FactoryGirl model,
  # though, because I feel like I have more control over the things I want to test (and it's faster--doesn't hit the DB). This
  # exposes the amount of stuff going on in the view quite nicely.  These also basically write themselves, so it's not that
  # painful, really.
  before(:each) do
    # TODO - generalize these extends for the other view specs.
    taxon_concept = double(TaxonConcept)
    taxon_concept.stub(:id) { 1 }
    details = double(TaxonDetails)
    details.stub(:taxon_concept) { taxon_concept }
    details.stub(:thumb?) { nil }
    toc_item = double(TocItem) # Gotta be in a toc...
    toc_item.stub(:label) { 'funfun' }
    @article.stub(:visibility_by_taxon_concept) { Visibility.visible }
    @article.stub(:vetted_by_taxon_concept) { Visibility.visible }
    details.stub(:each_toc_item).and_yield(toc_item, [@article])
    details.stub(:toc_items?) { true }
    details.stub(:toc_items_under?) { false }
    details.stub(:each_nested_toc_item) { [] }
    details.stub(:resources_links) { [] }
    details.stub(:literature_references_links) { [] }
    details.stub(:articles_in_other_languages?) { false }
    taxon_page = double(TaxonPage)
    assign(:taxon_page, taxon_page)
    assign(:details, details)
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_language) { Language.default }
  end

  shared_examples_for 'basic article' do

    # TODO - should test that the link is sanitized, still tagged, auto-linked, and has balanced tags.
    it 'should show the linked description' do
      render
      expect(rendered).to match /article copy linked/
    end

    it 'should NOT have the source link' do
      render
      expect(rendered).to_not have_link('http://sourcy.com')
    end

    context 'when added by a user' do

      let!(:user) { User.gen }

      before do
        @article.should_receive(:added_by_user?).at_least(1).times.and_return(true)
        udo = double(UsersDataObject)
        udo.stub(:user) { user }
        @article.should_receive(:users_data_object).at_least(1).times.and_return(udo)
      end

      it 'should have a link to the user' do
        render
        expect(rendered).to have_link(user.full_name)
      end

    end

    it "should show a visible reference" do
      ref = FactoryGirl.create(:ref)
      @article.should_receive(:published_refs).at_least(1).times.and_return([ref])
      render
      expect(rendered).to match ref.full_reference
    end
    it 'should show identifies associated with refs'

    it 'should NOT show invalid identifiers'

    it 'should do something with DOI identifiers in refs'

    it 'should linkify intifiers on refs'

  end

  context 'logged in' do

    before(:each) do
      user = double(User)
      user.stub(:min_curator_level?) { false }
      user.stub(:watch_collection) { nil }
      user.stub(:can_update?) { false } # This user won't own anything.
      view.stub(:current_user) { user }
      view.stub(:logged_in?) { true }
    end

    it_should_behave_like 'basic article'

  end

  context 'not logged in' do

    before(:each) do
      user = EOL::AnonymousUser.new(Language.default)
      view.stub(:current_user) { user }
      view.stub(:logged_in?) { false }
    end

    it_should_behave_like 'basic article'

  end

end
