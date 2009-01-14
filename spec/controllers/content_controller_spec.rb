require File.dirname(__FILE__) + '/../spec_helper'

def mock_content_page_for_each(name, type = :both)
  section = mock_model(ContentSection)
  page    = mock_model(ContentPage)
  ContentSection.should_receive(:find_pages_by_section).with(name).and_return([page])
  page.stub!(:url).and_return("")
  page.stub!(:open_in_new_window).and_return(false)
 #  page.should_receive(:each).and_return([page])
  if type == :both or type == :left
    page.should_receive(:left_content).and_return("#{name} Left Content Here")
  else
    page.stub!(:left_content).and_return("#{name} Left Content Here")
  end
  if type == :both or type == :main
    page.should_receive(:main_content).and_return("#{name} Main Content Here")
  else
    page.stub!(:main_content).and_return("#{name} Main Content Here")
  end
  if type == :menu
    page.should_receive(:title).exactly(2).times.and_return("Title for #{name}")
    page.should_receive(:key).exactly(2).times.and_return('en')
    page.should_receive(:page_url).and_return("URL#{name}URL")
    page.should_receive(:url).and_return("")
    page.should_receive(:open_in_new_window).and_return(false)
  end
  if type == :menu_item
    page.should_receive(:title).exactly(2).times.and_return("Title for #{name}")
    page.should_receive(:key).exactly(2).times.and_return('en')
    page.should_receive(:page_url).and_return("URL#{name}URL")
  end  
end

def mock_lang(language)
  lang = mock_model(Language)
  lang.should_receive(:name).exactly(2).times.and_return(language)
  lang.should_receive(:display_code).and_return(language[0..1].downcase)
  return lang
end

def have_link_to(where, content = nil)
  have_tag('a[href=?]', where, content)
end

describe ContentController do
  require 'hpricot' # One or two tricky queries that were easier with XPath.
  integrate_views # Since Gthe controllers and views are (presently) tightly coupled via the webservices...
  fixtures :content_sections, :content_pages, :top_images, :taxa, :data_objects, :data_objects_taxa
  
  before(:each) do
    @content_home_section  = mock_model(ContentSection)
    @content               = mock_model(ContentPage)

    ContentSection.stub!(:find_by_name).with('Home Page', {:include=>:content_pages}).and_return(@content_home_section)
    @content_home_section.stub!(:content_pages).and_return([@content])
    @content.stub!(:left_content).and_return("Main Page Left Content")
    @content.stub!(:main_content).and_return("Main Page Main Content")
    @content.stub!(:url).and_return("")
    @content.stub!(:show_in_new_window).and_return("")
    @user = mock_user # spec_helper
  end
  
  it 'should render appropriate content pages in alternate languages'
  
  it 'should render appropriate content pages' do
    ContentPage.should_receive(:get_by_page_name_and_language_abbr).with('Home',"en").and_return(@content)
    @content.should_receive(:left_content).and_return('The Left Content Here')
    @content.should_receive(:main_content).and_return('Main Content Here')
    @content.stub!(:url).and_return("")
    menu_items = ['Feedback', 'Press Room','Using the Site', 'About EOL', 'Footer']
    menu_items.each do |name|
      mock_content_page_for_each(name, :menu_item)
    end
    session[:user] = @user
    get 'index'
    response.should render_template('content/index')
    response.should have_tag('div#sidebar-a', 'The Left Content Here')
    response.should have_tag('div#sidebar-b', 'Main Content Here')
    menu_items.each do |name|
      response.should have_link_to(/.*URL#{name}URL/)
    end
  end
    
  it 'should create a new user (defaults tested on the model) if none is specified' do
    # This is "at least one time" because there may be calls to User.create_new in the code where a user is required.
    User.should_receive(:create_new).at_least(1).times.and_return(@user)
    get 'index'
  end
  
  it 'should skip featured species if not passed any' do
    session[:user] = @user
    TaxonConcept.should_receive(:exemplars).and_return(nil)
    get 'index'
    response.should_not have_tag('table#featured-species-table')
  end

  it 'should show six taxa at the top' do
    session[:user] = @user
    get 'index'
    doc = Hpricot(response.body)
    species_table = doc.at('table#top-photos-table')
    link_count  = 0
    species_table.search('a').each { |elem| link_count += 1 if elem['href'] =~ /taxa\/\d+/ }
    assert_equal 12, link_count, 'There should be two links for each of six species (total 12)'
    image_count = 0
    species_table.search('img').each { |elem| image_count += 1 }
    # I'm not aware of a good way to ensure the images aren't broken.  :\
    assert_equal 6, image_count, 'There should be five images--one for each of the popular species'
  end

  it 'should show login if no user specified on home page' do
    $ALLOW_USER_LOGINS = true
    get 'index'
    response.should have_link_to(/.*login.*/, 'login')
  end

  it 'should show NO login if logins are not allowed' do
    $ALLOW_USER_LOGINS = false
    get 'index'
    response.should_not have_link_to(/.*login.*/, 'login')
  end

  it 'should allow preference edits and logout, if user is logged in' do
    if $ALLOW_USER_LOGINS
      session[:user] = @user
      get 'index'
      response.should have_link_to(/.*taxa\/settings.*/)
      response.should have_link_to(logout_url)
    end
  end

  it 'should have a menu for all languages' do
    languages = []
    ['English', 'French', 'German', "Zimbawean"].each do |l|
      ml = mock_lang(l); ml.should_receive(:iso_639_1).at_least(1).times.and_return(l[0..1].downcase); languages << ml
    end
    Language.should_receive(:find_active).and_return(languages)
    get 'index'
    languages.each do |lang|
      response.should have_link_to(/.*set_language\?.*language=#{lang.iso_639_1}.*/)
    end
  end

  it 'should have a preferences menu link going to taxa/settings' do
    get 'index'
    response.should have_link_to(/.*taxa\/settings.*/)
  end
  
  it 'should show the survey link when that global variable is true' do
    $SHOW_SURVEYS = true
    get 'index'
    response.should have_link_to($SURVEY_URL)
  end
  
  it 'should hide the survey link when that global variable is false' do
    $SHOW_SURVEYS = false
    get 'index'
    # We also want to test that the other links didn't go away:
    response.should_not have_link_to($SURVEY_URL)
  end
  
  it 'should have a find form with text input called "q"' do
    get 'index'
    response.should have_tag('form[action=?]', /.*\/search/) do
      with_tag('input[type=text][name=q]')
    end
  end
    
  it 'should feature a species with image above matching text' do
    get 'index'
    response.should have_tag('h1', 'Featured')
    doc = Hpricot(response.body)
    feature = doc/"table#featured-species-table"
    if feature.nil?
      assert false, 'There was no featured species table'
    else
      links = feature/"a"
      has_image = false
      assert !(links.nil? or links.length == 0), 'The featured species had no links'
      assert_not_nil links[0].at('img'), 'There was no image for the featured species'
      assert_equal links[0]['href'], links[1]['href'], 'The links for the featured species were inconsistent (image/text)'
      assert_equal links[0].at('img')['alt'], links[1].inner_text, 'The names for the featured species were inconsistent (image alt/text)'
    end
  end
  
end

describe ContentController, 'explore taxa' do

  it 'should return javascript to replace an image on call to replace_single_explore_taxa' do
    concept = mock_model(TaxonConcept)
    concept.should_receive(:name).at_least(1).times.and_return("Foo baribus")
    picture = mock_model(DataObject)
    picture.stub!(:smart_medium_thumb).and_return("pretty_picture")
    random_taxon = mock_model(RandomTaxon)
    random_taxon.should_receive(:taxon_concept).at_least(1).times.and_return(concept)
    random_taxon.should_receive(:data_object).at_least(1).times.and_return(picture)
    random_taxon.should_receive(:taxon_concept_id).at_least(1).times.and_return(666)
    RandomTaxon.should_receive(:random).and_return(random_taxon)
    get 'replace_single_explore_taxa', :taxa_number => 1
    response.body.should match(/top_name_1.*href.*\/pages\/#{concept.id}.*>Foo baribus<\/a>.*br.*<p>Foo baribus<\/p>/) 
    response.body.should match(/top_image_tag_1.*alt.*Foo baribus/) 
    response.body.should match(/top_image_tag_1.*title.*Foo baribus/) 
    response.body.should match(/href.*\/pages\/666/) # gotta be a link to our taxon somewhere.
    response.body.should match(/image_tag_1.*src.*pretty_picture/) # gotta be some eye-candy
  end

  it 'should render nothing if RandomTaxa.random is nil (implies RandomTaxon.random is called)' do
    RandomTaxon.should_receive(:random).and_return(nil)
    get 'replace_single_explore_taxa', :taxa_number => 1
    response.body.strip.empty?.should be_true
  end

  it 'should render nothing if taxa_number is missing' do
    get 'replace_single_explore_taxa'
    response.body.strip.empty?.should be_true
  end

end
