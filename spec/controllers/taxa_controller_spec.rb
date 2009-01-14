require File.dirname(__FILE__) + '/../spec_helper'

class String
  def clean_hpricot
    return self.clone.strip.gsub(/\?/, ' ') # For some reason, Hpricot doesn't recognize the spaces in some values.  I didn't dig into it.
  end
end

def make_random_taxa
  list = []
  5.times do
    rand_tax = mock_model(RandomTaxon)
    rand_tax.should_receive(:name).at_least(1).times.and_return('Taxa randomicus')
    rand_tax.should_receive(:smart_thumb).and_return('<img src="foo" />')
    rand_tax.should_receive(:taxon_concept_id).at_least(1).times.and_return(1234)
    t_c = mock_model(TaxonConcept)
    #t_c.should_receive(:name).and_return(nil) # This ensures that nil values (which are possible) don't blow anything up
    #rand_tax.should_receive(:taxon_concept).at_least(1).times.and_return(t_c)
    rand_tax.should_receive(:quick_scientific_name).and_return("My name")
    rand_tax.should_receive(:quick_common_name).and_return("My name")
    list << rand_tax
  end
  RandomTaxon.should_receive(:random_set).and_return(list)
end

def tags_to_text(tag_list, nested_tag_type = 'span')
  tag_list.collect do |tag|
    if nested_tag_type.nil?
      tag
    else
      nested = tag.at(nested_tag_type)
      nested.nil? ? nil : nested.inner_text.clean_hpricot
    end
  end
end

describe TaxaController, '/taxa/' do
  controller_name :taxa
  it 'should redirect to /pages/ preserving parameters' do
    caf = mock_cafeteria_concept
    entry = mock_model(HierarchyEntry)
    entry.should_receive(:taxon_concept_id).and_return(caf.id)
    HierarchyEntry.should_receive(:find).and_return(entry)
    get 'taxa', :id => entry.id, :category_id => 13
    response.should redirect_to(:action => 'show', :controller => 'taxa', :category_id => 13, :id => caf.id)
  end
end

# We're using Hpricot because the HTML seems to be slightly malformed and the RSpec parser bugs out.
describe 'Taxa Controller show with views' do
  controller_name :taxa
  integrate_views
  require 'hpricot'

  # Languages are required by mock_cafeteria_concept
  fixtures :languages

  before do
    make_random_taxa
    @kingdoms = ['Animals', 'Archaea', 'Bacteria', 'Chromista', 'Fungi', 'Plants', 'Protozoa', 'Viruses']
    @expert_kingdoms = ['Animalia', 'Archaea', 'Bacteria', 'Chromista', 'Fungi', 'Plantae', 'Protozoa', 'Viruses']
    @mock_cafeteria_concept = mock_cafeteria_concept
    @id = @mock_cafeteria_concept.id
    TaxonConcept.should_receive(:find).with(@id.to_s).and_return(@mock_cafeteria_concept)
    # Again, these are all VERY SPECIFIC to Cafeteria Roenbergensis!  If that changes, the tests will fail:
    @common_name = 'Cafeteria roenbergensis'
    @formatted_common_name = "<i>#{@common_name}</i>"
    @scientific_name = 'Cafeteria roenbergensis'
    @formatted_scientific_name = "<i>#{@scientific_name}</i>"
    @authority = 'Fenchel & D.J. Patterson'
    @scientific_with_authority = "#{@scientific_name} #{@authority}"
    @formatted_with_authority = "<i>#{@scientific_name}</i> #{@authority}"
    @iucn_status   = 'SAMPLE CAFETERIA STATUS'
    @iucn_link     = 'http://www.iucn.org/'
    @popular_image_url_re = /#{@IMG_SERVER}\/2008\/10\/24\/01\/23456_small.png/
    @popular_image_citation_res = [/Some rights reserved/, /Tamara Clark/, /Eden Art/, /Scientific illustration/, /external_link\(.*http%3A%2F%2Fwww.tamaraclark.com%2F/]
    @num_images = 8
    @context = ['Chromista', 'Sagenista', 'Bicosoecids', 'Bicosoecales', 'Cafeteriaceae', 'Cafeteria']
    @expert_context = ['Chromista', 'Sagenista', 'Bicosoecophyceae', 'Bicosoecales', 'Cafeteriaceae', 'Cafeteria']
    @videos = ['Living cells of Cafeteria roenbergensis', 'Animation of flagellar beating in Cafeteria roenbergensis (stylized).']
    @toc = <<EOTOC
    *    Overview
    * Description
    * Succinct
    * Diagnosis of genus and species
    * Formal Description
    * Molecular Biology and Genetics
    * Etymology
    * Description of Rootlets
    * Ecology and Distribution
    * Distribution
    * Microbial Food Web
    * Autecology
    * Evolution and Systematics
    * Phylogeny
    * Higher Level Affiliations
    * References and More Information
    * Literature References
    * Editor's Links
    * Specialist Projects
EOTOC
    @toc = @toc.split('*').collect {|el| el.strip}[1..@toc.length] # The first one ends up empty because of the way I formatted it.
    @overview_re = /^Cafeteria roenbergensis is a single-celled flagellate from.*/
    # These are a workaround until I do something better with mock_cafeteria (or get rid of it entirely):
    @mock_cafeteria_concept.images[0].stub!(:id).and_return(667)
    @mock_cafeteria_concept.images[0].stub!(:public_tags).and_return([])
    DataObject.stub!(:find).with(667).and_return(@mock_cafeteria_concept.images[0])
  end

  it 'should not show any curators if there are none' do
    @mock_cafeteria_concept.should_receive(:approved_curators).and_return([])
    Hpricot(response.body).at('div#page-curator').nil?.should be_true
    get 'show', :id => @id
  end

  it 'should show "Page Curated By" (h2) with each curator\'s given and family names if there are curators' do
    curators = [mock_model(Agent, :given_name => 'Joseph', :family_name => 'Jumpin'),
                mock_model(Agent, :given_name => 'Daemon', :family_name => 'Segway')]
    @mock_cafeteria_concept.should_receive(:approved_curators).and_return(curators)
    get 'show', :id => @id
    curator_div = Hpricot(response.body).at('div#page-curator')
    curator_div.should_not be_nil
    curator_div.at('h2').inner_text.should match /page curated by/i
    (curator_div/'div.curator_name').each_with_index do |name, i|
      i.should_not == 2 # This means we got too many!
      name.at('a').inner_text.should == "#{curators[i].given_name} #{curators[i].family_name}"
    end
  end

  it 'should show title and subtitle at top, based on user expertise' do
    user = mock_user
    session[:user] = user
    @mock_cafeteria_concept.should_receive(:title).at_least(1).times.and_return('Successful title')
    @mock_cafeteria_concept.should_receive(:subtitle).at_least(1).times.and_return('Successful subtitle')
    get 'show', :id => @id
    doc = Hpricot(response.body)
    title = doc.at('div#page-title')
    title.at('h1').inner_html.should == 'Successful title'
    title.at('h2').inner_html.should == 'Successful subtitle'
  end

  it 'should change the classification names to scientific names if expert'

  it 'should show IUCN data' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    iucn = doc.at('span.iucn-status-value')
    assert_not_nil iucn, 'IUCN was missing'
    iucn_status_link = iucn.at('a')
    iucn_status_link.should_not be_nil
    iucn_status_link['href'].should == '#'
    iucn_status_link.inner_html.should match(/#{@iucn_status}/)
  end

  it 'should show expected images' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    main_img = doc.at('img#main-image')
    assert_not_nil main_img, 'Main image was missing'
    assert_equal main_img['alt'], @common_name, 'Main image was missing'
    small_images_div = doc.at('div.mc-img').at('div')
    assert_not_nil small_images_div, 'The images section was missing or did not have "mc-img" class'
    assert_equal @num_images, (small_images_div/"a").length, "we expected #{@num_images} small images for this taxon"
    # So... we *wanted* to test the names on the images, but each one /can/ have a slightly different name.  We decided non-null was enough.
    (small_images_div/"a").each do |link|
      assert_match /eol_update_image.*#{@id}/, link['onclick'], 'An image in the small images div was missing its onclick event'
      assert_not_nil link['title']
      img = link.at('img')
      assert_not_nil img, 'There is a wonky small image that is missing the actual image.  Go figure.'
      assert_not_nil img['alt']
    end
  end

  it 'should have the most popular image first, with citation in field-notes span' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    small_images = doc.at('div.mc-img').at('div')/'img'
    assert_not_nil small_images, 'The images section was missing, did not have "mc-img" class, or had no images'
    assert_match @popular_image_url_re, small_images[0]['src'],'the URL for the first image was not what we expected'
    @popular_image_citation_res.each do |regex|
      assert_match regex, small_images[0].parent['onclick'], 'there was no onclick javascript containing the citation information'
    end
    citation = doc.at('div.mc-notes').at('span#field-notes')
    assert_not_nil citation, 'There was no citation span with id of field-notes'
    # But that div is NOT filled by default.  That's handled by javascript:
    citation_js = doc.at('div#image-collection').at('script')
    assert_not_nil citation_js, 'There was no javascript within the mc-notes'
    @popular_image_citation_res.each do |regex|
      assert_match regex, citation_js.inner_html, 'one of the required elements of the citation was missing from the div'
    end
    # Note that this assumes that the FIRST link in the citation is the one we're matching.  Could there be more?  Not sure.
  end

  it 'should show distribution map' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    map = doc.at('img#map')
    assert_not_nil map,'Map is missing' 
    assert_equal "#{@scientific_with_authority} distribution map",map['alt']
  end

  it 'should have the proper number of videos available' do
    if @videos.length > 0
      get 'show', :id => @id
      doc = Hpricot(response.body)
      # Note we use sort to ensure the order is the same in both collections.
      video_texts = (doc.at('div#video-collection')/'a').collect {|a| a.inner_text }.sort
      @videos.sort.each_with_index do |video_name, i|
        assert_equal video_name, video_texts[i]
      end
    end
  end

  it 'should show the species in the expected taxonomic context'

  # We are no longer calling the kingdoms method for this:
  it 'should show all the other kingdoms (in order)' # do
    #WAIT kings = [mock_hierarchy_entry('A'), mock_hierarchy_entry('B'), mock_hierarchy_entry('C'), mock_hierarchy_entry('D'),
             #WAIT mock_hierarchy_entry('E'), mock_hierarchy_entry('F')]
    #WAIT # We add the mock's kingdom because it has its own class, and is tested elsewhere.  We only care about kings, above.
    #WAIT Hierarchy.default.should_receive(:kingdoms).and_return(kings + [@mock_cafeteria_concept.ancestry[0]])
    #WAIT get 'show', :id => @id
    #WAIT doc = Hpricot(response.body)
    #WAIT context = doc.at('ul#taxonomictext')
    #WAIT assert_not_nil context, 'The entire context is missing'
    #WAIT levels = (context/'li.kingdom')
    #WAIT kings.each_with_index do |kingdom, i|
      #WAIT puts "\n** Error: missing kingdom LI #{i}: #{kingdom.name}" if levels[i].nil?
      #WAIT levels[i].should_not be_nil
      #WAIT assert_match /#{kingdom.name}/, levels[i].at('span').inner_text.clean_hpricot
    #WAIT end  
  #WAIT end

  it 'should have a meter for detail level' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    assert_not_nil doc.at('div#slider'), 'slider div was missing'
    assert_not_nil doc.at('div#handle'), 'handle div was missing'
  end

  it 'should have all of the expected pages ordered in the TOC' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    toc_items = doc.at('ul#toc')/'li'
    assert_not_nil toc_items, 'Couldn\'t find the Table of Contents items'
    @toc.each_with_index do |entry, i|
      assert_not_nil toc_items[i], "Missing an item associated with '#{entry}''"
      assert_equal entry, toc_items[i].inner_text.strip
    end
  end

  it 'should have the overview by default' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    center = doc.at('div#center-page-content')
    assert_not_nil center, 'The entire center-page-content div was missing or had the wrong id'
    assert_equal 'Overview', center.at('h3').inner_text
    assert_not_nil doc.at('div.content-article'), 'The content article was missing'
    assert_match @overview_re, doc.at('div.content-article').at('p').inner_text.strip
  end

  it 'should have an explore pane with 5 species in it' do
    get 'show', :id => @id
    doc = Hpricot(response.body)
    explore = doc.at('div#internal-nav')
    assert_not_nil explore, 'Missing internal-nav div'
    count = 0
    (explore/"tr").each do |row|
      count += 1
      assert_not_nil row.at('img')
      assert_equal 2, (row/'a').length
    end
    assert_equal 5, count, 'Number of links in the Explore section was wrong'
  end

  it 'should have rendered the right template and the main layout (details of which are tested on the ContentController)' do
    get 'show', :id => @id
    response.should render_template('taxa/show_cached')
    assert_not_nil Hpricot(response.body).at('ul#global-navigation'), 'The global navigation list was not rendered.'
  end

  it 'should render "ping" images' do
    @mock_cafeteria_concept.should_receive(:ping_host_urls).and_return(['test'])
    get 'show', :id => @id
    found_ping = false
    (Hpricot(response.body).at('div#right-page-content')/'img').each do |img|
      found_ping = true if img['src'] == 'test'
    end
    found_ping.should be_true
  end

end

describe TaxaController, 'without views' do

  before do
    @mock_cafeteria_concept = mock_cafeteria_concept(false)
    TaxonConcept.should_receive(:find).with(@mock_cafeteria_concept.id.to_s).and_return(@mock_cafeteria_concept)
  end

  it 'should display the proper center content when a content_id is passed in' do
    mock_content = mock_model(TocItem)
    mock_dato    = mock_model(DataObject)
    mock_dato.stub!(:[]).with(:data_objects).and_return([])
    some_text    = "Yay, this is our text"
    @mock_cafeteria_concept.should_receive(:content_by_category).with(mock_content.id.to_s).and_return(mock_dato)
    get 'show', :id => @mock_cafeteria_concept.id, :category_id => mock_content.id
    assigns[:content].should == mock_dato
  end

end

describe 'Taxa Controller for non-existant taxon' do

  controller_name :taxa

  it 'should redirect on missing id' do
    the_get = Proc.new { get 'show' }
    the_get.should raise_error(Exception, 'taxa id not supplied')
  end

  it 'should redirect on bad id' do
    fake_id = 'doesnt_matter'
    TaxonConcept.should_receive(:find).with(fake_id).and_raise(ActiveRecord::RecordNotFound)
    the_get = Proc.new { get 'show', :id => fake_id }
    the_get.should raise_error(Exception, "taxa #{fake_id} does not exist")
  end

end

describe 'Taxa Controller fragment caching' do

  controller_name :taxa

  it 'should *not* cache a species page when caching is disabled'
  
  it 'should cache a species page when caching is enabled'
    
  it 'should expire a species page and its ancestors'
  

end

describe 'Taxa Controller search' do

  controller_name :taxa
  integrate_views
#  require 'Hpricot'

  it 'should return several spiders on search for "tarantula", under scientific names'

  it 'should return mola mola (among other things) on search for "mola mola", including common and scientific results'

  it 'should return [something] when searching for [something else] in French'

  it 'should have a header and footer'

  it 'should render the proper template'

  it 'should return suggested results for common searches'

end

describe TaxaController, 'Taxa Controller ajax calls' do

  it 'should return center content on get to content' do
    fake_id       = 6789
    content_id    = 1234
    content       = {:content_type => 'text', :category_name => 'whatever', :data_objects => []}
    taxon_concept = mock_model(TaxonConcept)
    taxon_concept.should_receive(:content_by_category).with(content_id).and_return(content)
    taxon_concept.should_receive(:current_user=)
    TaxonConcept.should_receive(:find).with(fake_id.to_s).and_return(taxon_concept)
    mock_toc = mock_model(TocItem)
    mock_toc.should_receive(:id).and_return(0) # This tests search-the-web.
    TocItem.should_receive(:search_the_web).and_return(mock_toc)
    get 'content', :id => fake_id, :category_id => content_id
    response.should render_template('taxa/_content.html.erb')
  end

  it 'should return search-the-web center content using the correct partial'

end
