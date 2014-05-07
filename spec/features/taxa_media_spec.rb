require "spec_helper"

describe 'Taxa media' do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :media_heavy
    @data = EOL::TestInfo.load('media_heavy')
    @taxon_page = TaxonPage.new(@data[:taxon_concept], EOL::AnonymousUser.new(Language.default))
    Capybara.reset_sessions!
    CuratorLevel.create_enumerated
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  it 'should show the taxon header' do
    visit taxon_media_path(@taxon_page)
    body.should have_selector('#page_heading') do
      with_tag('h1', /(#{@taxon_page.title_canonical})(\n|.)*?media/i)
    end
  end

  it 'should show a gallery of mixed media' do
    visit taxon_media_path(@taxon_page)
    body.should have_selector("li.sound")
    body.should have_selector("li.video")
    body.should have_selector("li.image")
  end

end
