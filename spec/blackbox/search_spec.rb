require File.dirname(__FILE__) + '/../spec_helper' 
require File.dirname(__FILE__) + '/../../lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

require 'solr_api'

def animal_kingdom
  @animal_kingdom ||= build_taxon_concept(:canonical_form => 'Animals',
                                          :parent_hierarchy_entry_id => 0,
                                          :depth => 0)
end

def recreate_indexes
  solr = SolrAPI.new
  solr.delete_all_documents
  solr.build_indexes
end

# Checks the table of results, makes sure it has the right string(s) and number of rows.
def assert_results(options)
  search_string = options[:search_string] || 'tiger'
  per_page = options[:per_page] || 10
  body =
    request("/search?q=#{search_string}&per_page=#{per_page}#{options[:page] ? "&page=#{options[:page]}" : ''}").body
  body.should have_tag('table[class=results_table]') do |table|
    header_index = 1
    result_index = header_index + options[:num_results_on_this_page]
    with_tag("tr:nth-child(#{result_index})")
    without_tag("tr:nth-child(#{result_index + 1})").should be_false
  end
end

def assert_tag_results(options)
  res = request("/search?search_type=tag&q=value#{options[:page] ? "&page=#{options[:page]}" : ''}").body
  res.should have_tag('div[class=serp_pagination]')
  res.should have_tag('table[class=results_table]') do |table|
    header_index = 1
    result_index = header_index + 1
    table.should have_tag("tr:nth-child(#{header_index})")
    options[:num_results_on_this_page].times do
      table.should have_tag("tr:nth-child(#{result_index})")
      result_index += 1
    end
    table.should_not have_tag("tr:nth-child(#{result_index})")
  end
end

describe 'Search' do

  before :all do
    truncate_all_tables
    Scenario.load :foundation
    # TODO - move these to a foundation for searching?
    @doesnt_exist = 'Bozo'
    @panda_name = 'panda'
    @panda = build_taxon_concept(:common_names => [@panda_name])
    @tiger_name = 'Tiger'
    @tiger = build_taxon_concept(:common_names => [@tiger_name],
                                 :vetted       => 'untrusted')
    @tiger_lilly_name = "#{@tiger_name} lilly"
    @tiger_lilly = build_taxon_concept(:common_names => 
                                        [@tiger_lilly_name, 'Panther tigris'],
                                       :vetted => 'unknown')
    @tiger_moth_name = "#{@tiger_name} moth"
    @tiger_moth = build_taxon_concept(:common_names => 
                                       [@tiger_moth_name, 'Panther moth'])
    @plantain_name   = 'Plantago major'
    @plantain_common = 'Plantain'
    @plantain = build_taxon_concept(:scientific_name => @plantain_name, :common_names => [@plantain_common])
    build_taxon_concept(:scientific_name => "#{@plantain_name} L.", :common_names => ["big #{@plantain_common}"])
    SearchSuggestion.gen(:taxon_id => @plantain.id, :scientific_name => @plantain_name,
                         :term => @plantain_name, :common_name => @plantain_common)
    @dog_name      = 'Dog'
    @domestic_name = "Domestic #{@dog_name}"
    @dog_sci_name  = 'Canis lupus familiaris'
    @wolf_name     = 'Wolf'
    @wolf_sci_name = 'Canis lupus'
    @dog  = build_taxon_concept(:scientific_name => @dog_sci_name, :common_names => [@domestic_name])
    @wolf = build_taxon_concept(:scientific_name => @wolf_sci_name, :common_names => [@wolf_name])
    SearchSuggestion.gen(:taxon_id => @dog.id, :term => @dog_name, :scientific_name => @dog.scientific_name,
                         :common_name => @dog.common_name)
    SearchSuggestion.gen(:taxon_id => @wolf.id, :term => @dog_name, :scientific_name => @wolf.scientific_name,
                         :common_name => @wolf.common_name)
    recreate_indexes
    @tiger_search = request("/search?q=#{@tiger_name}").body
  end

  it 'should return a helpful message if no results' do
    TaxonConcept.should_receive(:search_with_pagination).at_least(2).times.and_return([])
    request("/search?q=#{@doesnt_exist}").body.should have_tag('h3', :text => 'No search results were found')
  end

  it 'should redirect to species page if only 1 possible match is found (also for pages/searchterm)' do
    request("/search?q=#{@panda_name}").should redirect_to("/pages/#{ @panda.id }")
    request("/search/#{@panda_name}").should redirect_to("/pages/#{ @panda.id }")    
  end

  it 'should redirect to search page if a string is passed to a species page' do
    request("/pages/#{@panda_name}").should redirect_to("/search/#{@panda_name}")
  end

  it 'should show a list of possible results (linking to /taxa/search_clicked) if more than 1 match is found  (also for pages/searchterm)' do

    body = @tiger_search
    body.should have_tag('td', :text => @tiger_name)
    body.should have_tag('td', :text => @tiger_lilly_name)
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ @tiger_lilly.id }})
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ @tiger.id }})

  end

  it 'should paginate' do
    results_per_page = 2
    extra_results    = 1
    assert_results(:num_results_on_this_page => results_per_page, :per_page => results_per_page)
    assert_results(:num_results_on_this_page => extra_results, :page => 2, :per_page => results_per_page)
  end

  it 'return no suggested results for tiger' do
    body = @tiger_search
    body.should_not have_tag('table[summary=Suggested Search Results]')
  end

  it 'should return one suggested search' do
    res = request("/search?q=#{URI.escape @plantain_name.gsub(/ /, '+')}&search_type=text")
    res.body.should have_tag('table[summary=Suggested Search Results]') do |table|
      table.should have_tag("td", :text => @plantain_common)
    end
  end

  # When we first created suggested results, it worked fine for one, but failed for two, so we feel we need to test
  # two entires AND one entry...
  it 'should return two suggested searches' do
    res = request("/search?q=#{@dog_name}&search_type=text")
    res.body.should have_tag('table[summary=Suggested Search Results]') do |table|
      table.should have_tag("td", :text => @domestic_name)
      table.should have_tag("td", :text => @wolf_name)
    end
  end

  it 'should treat empty string search gracefully when javascript is switched off' do
    res = request('/search?q=')
    res.body.should_not include "500 Internal Server Error"
  end

  it 'should detect untrusted and unknown Taxon Concepts' do
    body = @tiger_search
    body.should match /td class=\"(odd|even)_untrusted/
    body.should match /td class=\"(odd|even)_unvetted/
  end
  
  it 'should show only common names which include whole search query' do
    res = request("/search?q=#{URI.escape @tiger_lilly_name}")
    res.headers['Location'].should match /\/pages\/\d+/
    res.status.should == 302
  end

  it 'should return preferred common name as "shown" name' do
    res = request("/search?q=panther")
    res.body.should include "shown as 'Tiger lilly'"
  end
  
  it 'should have odd and even rows in search result table' do
    body = @tiger_search
    body.should include "td class=\"odd"
    body.should include "td class=\"even"
  end 
  #-------- tag search -------

  it 'should find tags' do
    taxon_concept = build_taxon_concept(:images => [{}])
    image_dato   = taxon_concept.images.last
    user = User.gen :username => 'username', :password => 'password'
    image_dato.tag("key-old", "value-old", user)
    # during reharvesting this object will be recreated with the same guid and different id
    # it should still find all tags because it uses guid, not id for finding relevant information
    new_image_dato = DataObject.build_reharvested_dato(image_dato)
    new_image_dato.tag("key-new", "value-new", user)
    
    res = request('/search?q=value-old&search_type=tag')
    res.body.should include(taxon_concept.scientific_name)
  end

  # REMOVE AFTER PAGINATION IMPLEMENTING TODO
  it 'should show > 10 tags' do
    user   = User.gen :username => 'username', :password => 'password'
    all_tc = []
    amount_of_taxa  = 15
    
    amount_of_taxa.times do
      taxon_concept = build_taxon_concept(:images => [{}])
      image_dato    = taxon_concept.images.last
      image_dato.tag("key", "value", user)
      all_tc << taxon_concept.scientific_name
    end
        
    res = request('/search?search_type=tag&q=value')
    for tc_name in all_tc
      res.body.should include(tc_name)
    end
  end

  it 'should show unvetted status for tag search' do
    # body = @tiger_search
    #   body.should have_tag('td.odd_untrusted')
    #   body.should have_tag('td.odd_unvetted')
    user   = User.gen :username => 'username', :password => 'password'
    all_tc = []
    vetted_methods  = ['untrusted', 'unknown', 'trusted']
    
    vetted_methods.each do |v_method|
      taxon_concept = build_taxon_concept(:images => [{}], :vetted => v_method)
      image_dato    = taxon_concept.images.last
      image_dato.tag("key", "value", user)
      all_tc << taxon_concept.scientific_name
    end
        
    res = request('/search?search_type=tag&q=value')
    res.body.should match /(odd|even)[^_]/
    res.body.should match /(odd|even)_untrusted/
    res.body.should match /(odd|even)_unvetted/    
  end
    
  # WHEN WE HAVE PAGINATION FOR TAGS (TODO):
  #
  #   it 'should show pagination if there are > 10 tags' do
  #     user   = User.gen :username => 'username', :password => 'password'
  #     all_tc = []
  #     results_per_page = 10
  #     extra_results    = 3
  #     amount_of_taxa   = results_per_page + extra_results
  #     
  #     amount_of_taxa.times do
  #       taxon_concept = build_taxon_concept(:images => [{}])
  #       image_dato    = taxon_concept.images.last
  #       image_dato.tag("key", "value", user)
  #     end
  #         
  #     assert_tag_results(:num_results_on_this_page => results_per_page)
  #     assert_tag_results(:num_results_on_this_page => extra_results, :page => 2)    
  #   end
    
end
