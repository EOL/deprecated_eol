require File.dirname(__FILE__) + '/../spec_helper'

describe 'Taxa data tab basic tests' do
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @taxon_concept = build_taxon_concept
    @target_taxon_concept = build_taxon_concept
    @resource = Resource.gen
    @user = User.gen
    @default_data_options = { :subject => @taxon_concept, :resource => @resource }
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/weight',
      :object => '12345.0', :unit => 'http://eol.org/g'))
    @association = DataAssociation.new(@default_data_options.merge(:object => @target_taxon_concept,
      :type => 'http://eol.org/preys_on'))
    @user_added_data = UserAddedData.gen(:user => @user, :subject => @taxon_concept, :predicate => 'http://eol.org/length',
      :object => '9999.0')
    @master_curator = build_curator(@taxon_concept, :level => :master)
  end

  before(:each) do
    drop_all_virtuoso_graphs
  end

  it 'should not show data with there is nothing in the triplestore' do
    visit taxon_data_path(@taxon_concept.id)
    body.should_not have_selector("table.data tr")
  end

  it 'should display harvested measurements' do
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    body.should have_selector("table.data tr")
    body.should have_selector("table.data th span", :text => 'Weight')
    body.should have_selector("table.data td", :text => '12345.0')
    body.should include("Source: <a href=\"/content_partners/#{@resource.content_partner_id}")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@measurement.uri)}']", :text => "see this record in Virtuoso")
  end

  it 'should display harvested associations' do
    @association.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    body.should have_selector("table.data tr")
    body.should have_selector("table.data th span", :text => 'Preys On')
    body.should have_selector("table.data td a[href='/pages/#{@target_taxon_concept.id}/data']", :text => @target_taxon_concept.title_canonical)
    body.should include("Source: <a href=\"/content_partners/#{@resource.content_partner_id}")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@association.uri)}']", :text => "see this record in Virtuoso")
  end

  it 'should display user added data' do
    @user_added_data.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    body.should have_selector("table.data tr")
    body.should have_selector("table.data th span", :text => 'Length')
    body.should have_selector("table.data td", :text => '9999.0')
    body.should include("provided by <a href=\"/users/#{@user.id}\">#{@user.full_name}</a>")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@user_added_data.uri)}']", :text => "see this record in Virtuoso")
  end

  it 'should display known uri labels when available' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/mass', :object => 'http://eol.org/massive'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # readable label will be derived
    body.should have_selector("table.data td span", :text => 'Massive')
    # URI should not be used
    body.should_not have_selector("table.data td span", :text => 'http://eol.org/massive')
    body.should_not have_selector("table.data td span", :text => 'Really Really Heavy')
    KnownUri.gen_if_not_exists(:uri => 'http://eol.org/massive', :name => 'Really Really Heavy')
    visit taxon_data_path(@taxon_concept.id)
    body.should_not have_selector("table.data td span", :text => 'Massive')
    body.should_not have_selector("table.data td span", :text => 'http://eol.org/massive')
    # the label for the new KnownURI should get used
    body.should have_selector("table.data td span", :text => 'Really Really Heavy')
  end

  it 'should display units of measure when explicitly declared' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/mass',
      :object => '50', :unit => 'http://eol.org/kg'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # unit should not display until the unit is a KnownURI
    pattern = "50.0\n</span>\n <span>\nkilograms"
    body.should_not include(pattern)
    KnownUri.gen_if_not_exists(:uri => 'http://eol.org/kg', :name => 'kilograms', :uri_type => UriType.unit_of_measure)
    visit taxon_data_path(@taxon_concept.id)
    body.should include(pattern)
  end

  it 'should display units of measure when implied by measurement type' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/time', :object => '50'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # unit should not display until the predicate is associated with a unit, and that unit is a KnownURI
    body.should have_selector("table.data td[headers='http://eol.org/time'] span", :text => '50')
    pattern = "50.0\n</span>\n <span>\nhours"
    body.should_not include(pattern)
    time = KnownUri.gen_if_not_exists(:uri => 'http://eol.org/time', :name => 'time')
    hours = KnownUri.gen_if_not_exists(:uri => 'http://eol.org/hours', :name => 'hours', :uri_type => UriType.unit_of_measure)
    KnownUriRelationship.gen_if_not_exists(:from_known_uri => time, :to_known_uri => hours, :relationship_uri => KnownUriRelationship::MEASUREMENT_URI)
    visit taxon_data_path(@taxon_concept.id)
    body.should include(pattern)
  end

  it 'should allow master curators to add data' do
    login_as @master_curator
    visit(taxon_data_path(@taxon_concept))
    body.should_not have_tag("table.data")
    body.should have_tag("form#new_user_added_data")
    body.should have_tag("form#new_user_added_data input[@type='submit']", :value => "submit data value")
    within(:xpath, '//form[@id="new_user_added_data"]') do
      fill_in 'user_added_data_predicate', :with => 'http://eol.org/schema/terms/testingadddata'
      fill_in 'user_added_data_object', :with => 'testingadddata_value'
      click_button "submit data value"
    end
    visit(taxon_data_path(@taxon_concept))
    body.should have_tag("table.data")
    body.should include("testingadddata")
    body.should include("testingadddata_value")
    visit('/logout')
  end

end
