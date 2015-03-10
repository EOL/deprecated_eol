require "spec_helper"

describe 'Taxa details' do
  before(:all) do
    load_foundation_cache
  end
  
  it 'should start with no references' do
    tc = build_taxon_concept(comments: [], bhl: [], toc: [], sounds: [], youtube: [], flash: [], images: [])
    visit taxon_literature_path(tc)
    body.should include 'No references found.'
  end

  it 'should show references associated with data objects' do
    tc = build_taxon_concept(comments: [], bhl: [], toc: [], sounds: [], youtube: [], flash: [])
    d = tc.data_objects.last
    r = Ref.gen(full_reference: 'This is the full reference')
    DataObjectsRef.gen(data_object: d, ref: r)
    visit taxon_literature_path(tc)
    body.should include 'This is the full reference'
  end

  it 'should show identifiers associated with references' do
    tc = build_taxon_concept(comments: [], bhl: [], sounds: [], youtube: [], flash: [], images: [])
    d = tc.data_objects.where(data_type_id: DataType.text.id).last
    r = Ref.gen(full_reference: 'This is the full reference')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.url, identifier: 'http://si.edu/someref')
    RefIdentifier.gen(ref: r, ref_identifier_type: RefIdentifierType.doi, identifier: 'doi:10.1006/some.ref')
    DataObjectsRef.gen(data_object: d, ref: r)
    visit taxon_literature_path(tc)
    body.should have_tag("a[href='http://si.edu/someref']")
    body.should have_tag("a[href='http://dx.doi.org/10.1006/some.ref']")
  end

end
