require "spec_helper"

class EOL::NestedSet
 extend EOL::Data
end

require 'solr_api'

def assert_results(options)
  search_string = options[:search_string] || 'tiger'
  per_page = options[:per_page] || 10
  visit("/search?q=#{search_string}&per_page=#{per_page}#{options[:page] ? "&page=#{options[:page]}" : ''}")
  body.should have_selector('#main ul')
  result_index = options[:num_results_on_this_page]
  body.should have_selector("li:nth-child(#{result_index})")
  body.should_not have_selector("li:nth-child(#{result_index + 1})")
end

describe 'Search' do
  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:search_names)
    data = EOL::TestInfo.load('search_names')

    @panda                      = data[:panda]
    @name_for_all_types         = data[:name_for_all_types]
    @name_for_multiple_species  = data[:name_for_multiple_species]
    @unique_taxon_name          = data[:unique_taxon_name]
    @text_description           = data[:text_description]
    @image_description          = data[:image_description]
    @video_description          = data[:video_description]
    @sound_description          = data[:sound_description]
    @tiger_name                 = data[:tiger_name]
    @tiger                      = data[:tiger]
    @tiger_lilly_name           = data[:tiger_lilly_name]
    @tiger_lilly                = data[:tiger_lilly]
    @tricky_search_suggestion   = data[:tricky_search_suggestion]
    @suggested_taxon_name       = data[:suggested_taxon_name]
    @user1                      = data[:user1]
    @user2                      = data[:user2]
    @community                  = data[:community]
    @collection                 = data[:collection]
    @cms_page                   = data[:cms_page]

    # A taxon with a name we want:
    tc = build_taxon_concept(canonical_form: 'Blueberry cake',
                             comments: [], bhl: [], sounds: [], images: [], youtube: [], flash: [])
    # A trait with the same name:
    kuri = FactoryGirl.create(:known_uri_measurement, name: "Blueberry")
    instance = DataMeasurement.new(predicate: KnownUri.last.uri, :object => "13.8", :resource => Resource.last, :subject => tc)
    instance.add_to_triplestore
    Capybara.reset_sessions!
    visit('/logout')
    EOL::Data.make_all_nested_sets
    EOL::Data.flatten_hierarchies
    ci_solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    ci_solr_api.delete_all_documents
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
  end

  it 'should redirect to species page if only 1 possible match is found (also for pages/searchterm)' do
    visit("/search?q=#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
    visit("/search/#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
  end

  it 'should redirect to search page if a string is passed to a species page' do
    visit("/pages/#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
  end

  it 'should show a list of possible results (linking to /found) if more than 1 match is found  (also for pages/searchterm)' do
    visit("/search?q=#{@tiger_name}")
    page.should have_selector('li', text: @tiger_name)
    page.should have_selector("a[href*='/pages/#{@tiger.id}']")
    page.should have_selector('li', text: @tiger_lilly_name.capitalize_all_words)
    page.should have_selector("a[href*='/pages/#{@tiger_lilly.id}']")
  end

  it 'should be able to return suggested results for "bacteria"' do
    visit("/search?q=#{@tricky_search_suggestion}&search_type=text")
    page.should have_selector("#main li", text: @suggested_taxon_name.capitalize_all_words)
  end

  it 'should treat empty string search gracefully when javascript is switched off' do
    visit('/search?q=')
    body.should_not include "500 Internal Server Error"
  end

  it 'should show only common names which include whole search query' do
    visit("/search?q=#{URI.escape @tiger_lilly_name}")
    # should find only common names which have 'tiger lilly' in the name
    # we have only one such record in the test, so it redirects directly
    # to the species page
    current_path.should match /\/pages\/#{@tiger_lilly.id}/
  end

  it 'should return a helpful message if no results' do
    # TaxonConcept.should_receive(:search_with_pagination).at_least(1).times.and_return([])
    visit("/search?q=bozo")
    expect(page).to have_content(I18n.t(:no_results_for_search_term, search_term: 'bozo'))
  end

  it 'should place suggested search results at the top of the list' do
    visit("/search?q=#{@tricky_search_suggestion}&search_type=text")
    page.should have_selector("#search_results li", text: @suggested_taxon_name.capitalize_all_words)
  end

  it 'should sort by score by default' do
    visit("/search?q=#{@name_for_all_types}")
    default_body = body.gsub(/content[0-9]{1,2}\./, 'content1.')  # normalizing content server host names
    default_body.gsub!(/return_to.*?\"/, '')
    default_body.gsub!(/referred_page.*?\"/, '')
    default_body.gsub!(/<input id=\"search_log_id\".*?>/, '')  # removing search_log_id, which increments
    visit("/search?q=#{@name_for_all_types}&sort_by=score")
    newest_body = body.gsub(/content[0-9]{1,2}\./, 'content1.')  # normalizing content server host names
    newest_body.gsub!(/return_to.*?\"/, '')
    newest_body.gsub!(/referred_page.*?\"/, '')
    newest_body.gsub!(/<input id=\"search_log_id\".*?>/, '')  # removing search_log_id, which increments
    default_body.should == newest_body
  end

  it 'should sort by newest and oldest' do
    visit("/search?q=#{@name_for_all_types}&sort_by=newest")
    newest_results = []
    page.find(:xpath, "//div[@id='main']").all(:xpath, './/li').each{ |li| newest_results << li.text unless li.text.include?('Search scientific data on EOL') }

    visit("/search?q=#{@name_for_all_types}&sort_by=oldest")
    oldest_results = []
    page.find(:xpath, "//div[@id='main']").all(:xpath, './/li').each{ |li| oldest_results << li.text unless li.text.include?('Search scientific data on EOL') }

    newest_results.length.should == 8
    newest_results.length.should == oldest_results.length
    newest_results.should == oldest_results.reverse
  end

  # the following tests are for redirecting when there is only one result
  it 'should redirect to species page if only 1 possible match is found' do
    visit("/search?q=#{@unique_taxon_name}")
    current_path.should match /^\/pages\/#{@panda.id}/
  end

  it 'should redirect to a text page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@text_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to an image page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@image_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to a video page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@video_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to a sound page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@sound_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to user page if only 1 possible match is found' do
    visit("/search?q=#{@user1.username}")
    current_path.should match /^\/users\/#{@user1.id}/
  end

  it 'should redirect to cms page if only 1 possible match is found' do
    visit("/search?q=#{@cms_page.title}")
    current_path.should match /^\/info\/#{@cms_page.content_page_id}/
  end

  it 'should redirect to community page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@community.description)}")
    current_path.should match /^\/communities\/#{@community.id}/
  end

  it 'should redirect to collection page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@collection.name)}")
    current_path.should match /^\/collections\/#{@collection.id}/
  end



  # the following tests are for testing filtering. There is an entry for panda in each category, but only one, so
  # we should get redirected when the filter is on
  it 'should return all results when not filtering' do
    visit("/search?q=#{@name_for_all_types}")
    current_path.should match /^\/search/
    expect(page).to have_content("8 results for #{@name_for_all_types}")

    visit search_path(q: @name_for_all_types, type: ['all'])
    current_path.should match /^\/search/
    expect(page).to have_content("8 results for #{@name_for_all_types}")
  end

  it 'should filter by collection' do
    visit search_path(q: @name_for_all_types, type: ['collection'])
    current_path.should match /^\/collections\/#{@collection.id}/
  end

  it 'should filter by community' do
    visit search_path(q: @name_for_all_types, type: ['community'])
    current_path.should match /^\/communities\/#{@community.id}/
  end

  it 'should filter by image' do
    visit search_path(q: @name_for_all_types, type: ['image'])
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by sound' do
    visit search_path(q: @name_for_all_types, type: ['sound'])
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by video' do
    visit search_path(q: @name_for_all_types, type: ['video'])
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by text' do
    visit search_path(q: @name_for_all_types, type: ['text'])
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by taxon concept' do
    visit search_path(q: @name_for_all_types, type: ['taxon_concept'])
    current_path.should match /^\/pages\/#{@panda.id}/
  end

  it 'should filter by user' do
    visit search_path(q: @name_for_all_types, type: ['user'])
    current_path.should match /^\/users\/#{@user2.id}/
  end

  it 'should only show next and previous links when necessary' do
    # make enough so paging kicks in
    26.times do |i|
      User.gen(username: "testingsearchpaging #{i}")
    end
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    visit("/search?q=testingsearchpaging&page=1")
    body.should_not include "see previous"
    body.should include "see next"

    visit("/search?q=testingsearchpaging&page=2")
    body.should include "see previous"
    body.should_not include "see next"
  end

  it 'should properly list matches found on names which are not the preferred names' do
    h = Hierarchy.gen(browsable: 1)
    other_preferred_name = Name.gen(canonical_form: CanonicalForm.gen(string: 'Ailuropoda melanoleuca'),
      string: 'Ailuropoda melanoleuca',
      italicized: '<i>Ailuropoda melanoleuca</i>')
    entry = build_hierarchy_entry(0, @panda, other_preferred_name, hierarchy: h )
    synonym = Synonym.gen(hierarchy: h, hierarchy_entry: entry, synonym_relation: SynonymRelation.synonym,
      name: Name.gen(canonical_form: CanonicalForm.gen(string: 'Itsapanda'),
        string: 'Itsapanda',
        italicized: '<i>Itsapanda</i>'))

    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    visit("/search?q=Ailuropoda%20melanoleuca&show_all=1")
    body.should have_selector('.alternate_name', text: 'Alternative name:')
    body.should have_selector('.alternate_name', text: 'Ailuropoda melanoleuca')

    visit("/search?q=Itsapanda&show_all=1")
    body.should have_selector('.alternate_name', text: 'Alternative name:')
    body.should have_selector('.alternate_name', text: 'Itsapanda')

    visit("/search?q=trigger&show_all=1")
    body.should have_selector('.alternate_name', text: 'Alternative common name:')
    body.should have_selector('.alternate_name', text: 'Trigger')
  end

  context 'With a taxon result and a trait result' do

    before do
      visit(search_url(q: 'Blueberry'))
    end

    # Technically, we could check ALL of the other filter types are disabled, but this is a sanity check that is helpful and images aren't going away any
    # time soon.
    it 'gives no_results class to images' do
      expect(body).to have_selector('.no_results input#type_image')
    end

    it 'does not give a class to all results' do
      expect(body).to_not have_selector('.no_results input#type_all')
    end

    context 'when you click on traits' do

      before do
        visit(search_url(q: 'Blueberry', type: ['data']))
      end

      it 'still gives no_results class to images' do
        expect(body).to have_selector('.no_results input#type_image')
      end

      it 'still does not give a class to all results' do
        expect(body).to_not have_selector('.no_results input#type_all')
      end

    end

  end

end
