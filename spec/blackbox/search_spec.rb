require File.dirname(__FILE__) + '/../spec_helper' 
require File.dirname(__FILE__) + '/../../lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

def animal_kingdom
  @animal_kingdom ||= build_taxon_concept(:canonical_form => 'Animals',
                                          :parent_hierarchy_entry_id => 0,
                                          :depth => 0)
end

def create_fake_search_data(name)
  next_id ||= 1
  dato ||= DataObject.gen(:data_type_id => DataType.image_type_ids.first)
  {'taxon_concept_id' => [next_id += 1],
   'preferred_scientific_name' => [name],
   'scientific_name' => [name],
   'common_name' => [name],
   'top_image_id' => dato.id
  }
end

def create_many_taxa(count, options = {})
  options[:base_name] ||= 'Tiger'
  results = [] ; options[:extra_string] ||= 'lilly'
  count.times do
    results << create_fake_search_data("#{options[:base_name]} #{options[:extra_string]}")
    options[:extra_string].succ!
  end
  stub_search_method(results, options)
end

# Ick.
#
# There are a lot of stubs here, to account for the many different situations in which these things /could/ get called.
# Sadly, this is the nature of using .with() on stubs: you need to be specific with the params, and there are variations
# in this case.
#
# Another thing to note here is that the result-set needs to be paginatated.
#
# Also: this assumes that the search will ALWAYS be "tiger".
def stub_search_method(results, options = {})
  # This is the "blanket" response, which handles the cases where we don't want results for a given search call:
  TaxonConcept.stub!(:search_with_pagination).and_return([].paginate(:page => 2, :per_page => 10))
  options[:pages] ||= 1
  current_page = 1
  options[:pages].times do 
    # These are the "normal" options, used when calling search correctly.
    options_we_expect = {"action"=>"search", "search_type"=>:scientific_name, "q"=>'tiger', "controller"=>"taxa"}
    # These are the "weird" options, caused by searches that result from /pages/tiger URLs.  Peter's code.  ;)
    alt_options_we_expect = {"action"=>"search", "search_type"=>:scientific_name, "id"=>'tiger', "controller"=>"taxa"}
    options_we_expect.merge!({'page' => current_page.to_s}) if current_page > 1
    # Scientific names:
    TaxonConcept.stub!(:search_with_pagination).with(
      'tiger', alt_options_we_expect).and_return(options[:no_sci_result] ?
                                                  [].paginate(:page => current_page, :per_page => 10) :
                                                  results.paginate(:page => current_page, :per_page => 10))
    TaxonConcept.stub!(:search_with_pagination).with(
      'tiger', options_we_expect).and_return(options[:no_sci_result] ?
                                              [].paginate(:page => current_page, :per_page => 10) :
                                              results.paginate(:page => current_page, :per_page => 10))
    # Common names:
    TaxonConcept.stub!(:search_with_pagination).with(
      'tiger', alt_options_we_expect.merge({'search_type' => :common_name})).and_return(
        results.paginate(:page => current_page, :per_page => 10))
    TaxonConcept.stub!(:search_with_pagination).with(
      'tiger', options_we_expect.merge({'search_type' => :common_name})).and_return(
        results.paginate(:page => current_page, :per_page => 10))
    current_page += 1
  end
end

# Checks the table of results, makes sure it has the right string(s) and number of rows.
def assert_results(options)
  body = request("/search?q=tiger#{options[:page] ? "&page=#{options[:page]}" : ''}").body
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
    TaxonConcept.should_receive(:search_with_pagination).at_least(2).times.and_return([])
    request('/search?q=tiger').body.should have_tag('h3', :text => 'No search results were found')
  end

  it 'should redirect to species page if only 1 possible match is found (also for pages/searchterm)' do
    tiger = create_fake_search_data('Tiger')
    build_taxon_concept(:id => tiger['taxon_concept_id'])
    stub_search_method([tiger], :no_sci_result => true)
    request('/search?q=tiger').should redirect_to("/pages/#{ tiger['taxon_concept_id'] }")
    request('/search/tiger').should redirect_to("/pages/#{ tiger['taxon_concept_id'] }")    
  end

  it 'should redirect to search page if a string is passed to a species page' do
    tiger = create_fake_search_data('Tiger')
    stub_search_method([tiger], :no_sci_result => true)
    request('/pages/tiger').should redirect_to("/search/tiger")
  end

  it 'should show a list of possible results (linking to /taxa/search_clicked) if more than 1 match is found  (also for pages/searchterm)' do

    lilly = create_fake_search_data('Tiger Lilly')
    tiger = create_fake_search_data('Tiger')
    stub_search_method([lilly, tiger])

    body = request('/search?q=tiger').body
    body.should have_tag('td', :text => 'Tiger Lilly')
    body.should have_tag('td', :text => 'Tiger')
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ lilly['taxon_concept_id'] }})
    body.should have_tag('a[href*=?]', %r{/taxa/search_clicked/#{ tiger['taxon_concept_id'] }})

  end

  it 'should paginate' do
    results_per_page = 10
    extra_results    = 4

    create_many_taxa(results_per_page + extra_results, :pages => 2)

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
