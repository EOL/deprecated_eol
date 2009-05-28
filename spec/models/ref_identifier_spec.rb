require File.dirname(__FILE__) + '/../spec_helper'

describe RefIdentifier do

  describe 'link_to_identifier' do

    before(:each) do
      url_type    = RefIdentifierType.gen(:label => 'url')
      doi_type    = RefIdentifierType.gen(:label => 'doi')
      bad_type    = RefIdentifierType.gen(:label => 'weird')
      @url        = 'some/url/path'
      @http_url   = "http://#{@url}"
      @clean_doi  = '10.12355/foo/bar.baz.230'
      @linked_doi = "http://dx.doi.org/#{@clean_doi}"
      @weird_identifier            = RefIdentifier.gen(:ref_identifier_type => bad_type, :identifier => @url)
      @ref_identifier_with_no_http = RefIdentifier.gen(:ref_identifier_type => url_type, :identifier => @url)
      @ref_identifier_with_http    = RefIdentifier.gen(:ref_identifier_type => url_type, :identifier => @http_url)
      @doi_with_garbage            = RefIdentifier.gen(:ref_identifier_type => doi_type,
                                                       :identifier => "doi: #{@clean_doi} more crud")
      @doi_with_link               = RefIdentifier.gen(:ref_identifier_type => doi_type,
                                                       :identifier => @linked_doi)
    end

    it 'should add http:// to urls when it\'s missing one' do
      @ref_identifier_with_no_http.link_to_identifier.should == @http_url
    end

    it 'should NOT add http:// to urls that already have one' do
      @ref_identifier_with_http.link_to_identifier.should == @http_url
    end

    it 'should only grab DOI identifiers, not the extra garbage' do
      @doi_with_garbage.link_to_identifier.should == @linked_doi
    end

    it 'should not add the DOI link if it is already there' do
      @doi_with_link.link_to_identifier.should == @linked_doi
    end

    it 'should return the identifier as-is, if we don\'t know the type' do
      @weird_identifier.link_to_identifier.should == @url
    end

  end

  it 'should return true for display? on url identifiers' do
    identifier = RefIdentifier.gen(:ref_identifier_type => RefIdentifierType.gen(:label => 'url'))
    identifier.display?.should be_true
  end

  it 'should return true for display? on doi identifiers' do
    identifier = RefIdentifier.gen(:ref_identifier_type => RefIdentifierType.gen(:label => 'doi'))
    identifier.display?.should be_true
  end

  it 'should return false for display? on non-url-or-doi identifiers' do
    identifier = RefIdentifier.gen(:ref_identifier_type => RefIdentifierType.gen(:label => 'whatever'))
    identifier.display?.should_not be_true
  end

  it 'should call a doi type a doi, not a url' do
    identifier = RefIdentifier.gen(:ref_identifier_type => RefIdentifierType.gen(:label => 'doi'))
    identifier.doi?.should be_true
    identifier.url?.should_not be_true
  end

  it 'should call a url type a url, not a doi' do
    identifier = RefIdentifier.gen(:ref_identifier_type => RefIdentifierType.gen(:label => 'url'))
    identifier.url?.should be_true
    identifier.doi?.should_not be_true
  end

end
