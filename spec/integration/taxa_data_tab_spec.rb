require File.dirname(__FILE__) + '/../spec_helper'

describe 'Taxa data tab basic tests' do
  before(:all) do
    load_foundation_cache
    drop_all_virtuoso_graphs
    @taxon_concept = build_taxon_concept
    @target_taxon_concept = build_taxon_concept
    @resource = Resource.gen
    @user = User.gen
    @measurement = DataMeasurement.new(:subject => @taxon_concept, :predicate => 'http://eol.org/weight',
      :object => '12345', :unit => 'http://eol.org/grams', :resource => @resource)
    @association = DataAssociation.new(:subject => @taxon_concept, :object => @target_taxon_concept,
      :type => 'http://eol.org/preys_on', :resource => @resource)
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
    body.should have_selector("table.data td span", :text => '12345')
    body.should have_selector("table.data td table.meta")
    body.should have_selector("table.meta th[title='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']", :text => 'Type')
    body.should have_selector("table.meta td[title='http://rs.tdwg.org/dwc/terms/MeasurementOrFact']", :text => 'Measurement Or Fact')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementType']", :text => 'Measurement Type')
    body.should have_selector("table.meta td[title='http://eol.org/weight']", :text => 'Weight')
    body.should have_selector("table.meta th[title='http://rs.tdwg.org/dwc/terms/measurementValue']", :text => 'Measurement Value')
    body.should have_selector("table.meta td", :text => '12345')
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
    body.should have_selector("table.data td span", :text => '9999')
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
end
