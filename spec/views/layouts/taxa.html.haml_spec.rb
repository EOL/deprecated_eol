require 'spec_helper'

describe "layouts/taxa" do

  before(:all) do
    Language.create_english
  end

  before(:each) do # NOTE - these #double methods *only* work in a before :each block, not an :all. Don't move them.
    @user = double(EOL::AnonymousUser, watch_collection: nil, min_curator_level?: false, is_curator?: false)
    @taxon_concept = double(TaxonConcept)
    @taxon_concept.stub(:id) { 1 }
    @taxon_page = double(TaxonPage)
    @taxon_page.stub(:classification_filter?) { false }
    @taxon_page.stub(:can_be_reindexed?) { false }
    @taxon_page.stub(:media_count) { 0 }
    @taxon_page.stub(:maps_count) { 0 }
    assign(:taxon_page, @taxon_page)
    assign(:taxon_concept, @taxon_concept)
    assign(:preferred_common_name, "Common Spec Runner")
    view.stub(:current_user) { @user }
    view.stub(:logged_in?) { false }
    view.stub(:meta_data) { {} } # TODO - we should test this stuff.
    view.stub(:current_language) { Language.default }
    view.stub(:current_url) { 'http://yes.we/really_have/this-helper.method' }
  end

  it "should NOT convert ampresands or apostrophes in common names" do
    assign(:preferred_common_name, "Tom & Jerry's")
    render
    expect(rendered).to match /#{"Tom & Jerry's"}/
  end

  it 'should have a heading in the title' do
    render
    expect(rendered).to have_css('#page_heading h2')
  end

end
