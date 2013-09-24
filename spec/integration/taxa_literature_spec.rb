require File.dirname(__FILE__) + '/../spec_helper'
require 'nokogiri'

describe 'Taxa literature' do
  before(:all) do
    load_foundation_cache
  end
  
  it 'should note when there is no literature' do
    tc = build_taxon_concept
    visit taxon_literature_path(tc)
    body.should_not have_tag('ul.ref_list')
  end

  it 'should show references associated with data objects' do
    tc = build_taxon_concept
    d = tc.data_objects.where(:data_type_id => DataType.text.id).last
    r = Ref.gen(:full_reference => 'This is the full reference')
    DataObjectsRef.gen(:data_object => d, :ref => r)
    visit taxon_literature_path(tc)
    body.should have_tag('ul.ref_list')
    body.should include 'This is the full reference'
  end

  it 'should show identifiers associated with references' do
    tc = build_taxon_concept
    d = tc.data_objects.where(:data_type_id => DataType.text.id).last
    r = Ref.gen(:full_reference => 'This is the full reference')
    RefIdentifier.gen(:ref => r, :ref_identifier_type => RefIdentifierType.url, :identifier => 'http://si.edu/someref')
    RefIdentifier.gen(:ref => r, :ref_identifier_type => RefIdentifierType.doi, :identifier => 'doi:10.1006/some.ref')
    DataObjectsRef.gen(:data_object => d, :ref => r)
    visit taxon_literature_path(tc)
    body.should have_tag('ul.ref_list')
    body.should have_tag("a[href='http://si.edu/someref']")
    body.should have_tag("a[href='http://dx.doi.org/10.1006/some.ref']")
  end

end
