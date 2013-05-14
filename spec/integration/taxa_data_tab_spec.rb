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
      :object => '12345', :unit => 'http://eol.org/g'))
    @association = DataAssociation.new(@default_data_options.merge(:object => @target_taxon_concept,
      :type => 'http://eol.org/preys_on'))
    @user_added_data = UserAddedData.gen(:user => @user, :subject => @taxon_concept, :predicate => 'http://eol.org/length',
      :object => '9999')
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
    body.should have_selector("table.data th span[title='http://eol.org/weight']", :text => 'Weight')
    body.should have_selector("table.data td", :text => '12345')
    body.should have_selector("table.data td table.meta")
    body.should have_selector("table.meta th[title='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']", :text => 'Type')
    body.should have_selector("table.meta td[title='http://rs.tdwg.org/dwc/terms/MeasurementOrFact']", :text => 'Measurement Or Fact')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementType']", :text => 'Measurement Type')
    body.should have_selector("table.meta td[title='http://eol.org/weight']", :text => 'Weight')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementValue']", :text => 'Measurement Value')
    body.should have_selector("table.meta td", :text => '12345')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementUnit']", :text => 'Measurement Unit')
    body.should have_selector("table.meta td", :text => @measurement.metadata['http://rs.tdwg.org/dwc/terms/measurementUnit'])
    body.should include("Source: <a href=\"/content_partners/#{@resource.content_partner_id}")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@measurement.uri)}']", :text => @measurement.uri)
  end

  it 'should display harvested associations' do
    @association.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    body.should have_selector("table.data tr")
    body.should have_selector("table.data th span[title='http://eol.org/preys_on']", :text => 'Preys On')
    body.should have_selector("table.data td a[href='/pages/#{@target_taxon_concept.id}/data']", :text => @target_taxon_concept.subtitle)
    body.should have_selector("table.data td table.meta")
    body.should have_selector("table.meta th[title='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']", :text => 'Type')
    body.should have_selector("table.meta td[title='http://eol.org/schema/Association']", :text => 'Association')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/taxonID']", :text => 'Taxon Id')
    body.should have_selector("table.meta td a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@association.taxon_uri)}']",
      :text => @association.taxon_uri)
    body.should have_selector("table.meta th[title='http://eol.org/schema/targetTaxonID']", :text => 'Target Taxon Id')
    body.should have_selector("table.meta td a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@association.target_taxon_uri)}']",
      :text => @association.target_taxon_uri)
    body.should have_selector("table.meta th[title='http://eol.org/schema/associationType']", :text => 'Association Type')
    body.should have_selector("table.meta td", :text =>
      EOL::Sparql.uri_to_readable_label(@measurement.metadata['http://eol.org/schema/associationType']))
    body.should include("Source: <a href=\"/content_partners/#{@resource.content_partner_id}")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@association.uri)}']", :text => @association.uri)
  end

  it 'should display user added data' do
    @user_added_data.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    body.should have_selector("table.data tr")
    body.should have_selector("table.data th span[title='http://eol.org/length']", :text => 'Length')
    body.should have_selector("table.data td", :text => '9999')
    body.should have_selector("table.data td table.meta")
    body.should have_selector("table.meta th[title='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']", :text => 'Type')
    body.should have_selector("table.meta td[title='http://rs.tdwg.org/dwc/terms/MeasurementOrFact']", :text => 'Measurement Or Fact')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementType']", :text => 'Measurement Type')
    body.should have_selector("table.meta td[title='http://eol.org/length']", :text => 'Length')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementValue']", :text => 'Measurement Value')
    body.should have_selector("table.meta td", :text => '9999')
    body.should include("provided by <a href=\"/users/#{@user.id}\">#{@user.full_name}</a>")
    body.should have_selector("li a[href='#{$VIRTUOSO_FACET_BROWSER_URI_PREFIX + CGI.escape(@user_added_data.uri)}']", :text => @user_added_data.uri)
  end

  it 'should display known uri labels when available' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/mass', :object => 'http://eol.org/massive'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # readable label will be derived
    body.should have_selector("table.data td span[title='http://eol.org/massive']", :text => 'Massive')
    # URI should not be used
    body.should_not have_selector("table.data td span[title='http://eol.org/massive']", :text => 'http://eol.org/massive')
    body.should_not have_selector("table.data td span[title='http://eol.org/massive']", :text => 'Really Really Heavy')
    KnownUri.gen_if_not_exists(:uri => 'http://eol.org/massive', :name => 'Really Really Heavy')
    visit taxon_data_path(@taxon_concept.id)
    body.should_not have_selector("table.data td span[title='http://eol.org/massive']", :text => 'Massive')
    body.should_not have_selector("table.data td span[title='http://eol.org/massive']", :text => 'http://eol.org/massive')
    # the label for the new KnownURI should get used
    body.should have_selector("table.data td span[title='http://eol.org/massive']", :text => 'Really Really Heavy')
  end

  it 'should display units of measure when explicitly declared' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/mass',
      :object => '50', :unit => 'http://eol.org/kg'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # unit should not display until the unit is a KnownURI
    body.should_not include("<td>\n50\n<span title=\"http://eol.org/kg\">\nkilograms")
    KnownUri.gen_if_not_exists(:uri => 'http://eol.org/kg', :name => 'kilograms', :is_unit_of_measure => true)
    visit taxon_data_path(@taxon_concept.id)
    body.should include("<td>\n50\n<span title=\"http://eol.org/kg\">\nkilograms")
  end

  it 'should display units of measure when implied by measurement type' do
    @measurement = DataMeasurement.new(@default_data_options.merge(:predicate => 'http://eol.org/time', :object => '50'))
    @measurement.update_triplestore
    visit taxon_data_path(@taxon_concept.id)
    # unit should not display until the predicate is associated with a unit, and that unit is a KnownURI
    body.should_not include("<td>\n50\n<span title=\"http://eol.org/hours\">\nhours")
    time = KnownUri.gen_if_not_exists(:uri => 'http://eol.org/time', :name => 'time')
    hours = KnownUri.gen_if_not_exists(:uri => 'http://eol.org/hours', :name => 'hours', :is_unit_of_measure => true)
    KnownUriRelationship.gen_if_not_exists(:from_known_uri => time, :to_known_uri => hours, :relationship_uri => KnownUriRelationship::MEASUREMENT_URI)
    visit taxon_data_path(@taxon_concept.id)
    body.should include("<td>\n50\n<span title=\"http://eol.org/hours\">\nhours")
  end

end
