require File.dirname(__FILE__) + '/../spec_helper' 
require File.dirname(__FILE__) + '/../../lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

def animal_kingdom
  @animal_kingdom ||= build_taxon_concept(:canonical_form => 'Animals',
                                          :parent_hierarchy_entry_id => 0,
                                          :depth => 0)
end

def create_many_taxa(count, options = {})
  options[:base_name] ||= 'Tiger'
  rv = [] ; options[:extra_string] ||= 'lilly'
  count.times do
    rv << create_taxon("#{options[:base_name]} #{options[:extra_string]}")
    options[:extra_string].succ!
  end
end

def assert_results(options)
  body = request("/search?q=tiger#{options[:page] ? "&page=#{options[:page]}" : ''}").body
  body.should have_tag('div[class=serp_pagination]')
  body.should have_tag('table[class=results_table]') do |table|
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

  def create_taxon(namestring)
    taxa = build_taxon_concept(:canonical_form => namestring, :depth => 1,
                               :parent_hierarchy_entry_id => animal_kingdom.hierarchy_entries.first.id)
    EOL::NestedSet.make_all_nested_sets
    EOL::NestedSet.recreate_normalized_names_and_links
    return taxa
  end
  
  before(:each) do
    Scenario.load :foundation
    TaxonConcept.delete_all
    TaxonConceptContent.delete_all
    Name.delete_all           # Lest we get duplicate strings...
    NormalizedName.delete_all # ...Just because I know searches are based on normalized names
  end
  
  before :all do
    truncate_all_tables
  end

  it 'should return a helpful message if no results' do
    request('/search?q=tiger').body.should include("Your search on 'tiger' did not find any matches")
  end

  it 'should redirect to species page if only 1 possible match is found (also for pages/searchterm)' do
    tiger = create_taxon('Tiger')
    request('/search?q=tiger').should redirect_to("/pages/#{ tiger.id }")
    request('/search/tiger').should redirect_to("/pages/#{ tiger.id }")    
  end

  it 'should redirect to search page if a string is passed to a species page' do
    tiger = create_taxon('Tiger')
    request('/pages/tiger').should redirect_to("/search/tiger")
  end

  it 'should show a list of possible results (linking to /taxa/search_clicked) if more than 1 match is found  (also for pages/searchterm)' do

    lilly = create_taxon('Tiger Lilly')
    tiger = create_taxon('Tiger')

    body = request('/search?q=tiger').body
    body.should include(lilly.quick_scientific_name(:italicized))
    body.should include(tiger.quick_scientific_name(:italicized))
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ lilly.id }})
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ tiger.id }})

  end
  
  it 'should paginate' do
    results_per_page = 10
    extra_results   = 4
  
    create_many_taxa(results_per_page + extra_results)
  
    assert_results(:num_results_on_this_page => results_per_page)
    assert_results(:num_results_on_this_page => extra_results, :page => 2)
  end
  
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
    res.body.should include(taxon_concept.name)
  end

#   remove after pagination implementing
  it 'should show > 10 tags' do
    user   = User.gen :username => 'username', :password => 'password'
    all_tc = []
    amount_of_taxa  = 15
    
    amount_of_taxa.times do
      taxon_concept = build_taxon_concept(:images => [{}])
      image_dato    = taxon_concept.images.last
      image_dato.tag("key", "value", user)
      all_tc << taxon_concept.name
    end
        
    res = request('/search?search_type=tag&q=value')
    for tc_name in all_tc
      res.body.should include(tc_name)
    end
  end
  
# # open after pagination implementing  
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
