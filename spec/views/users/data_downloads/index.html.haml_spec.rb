require 'spec_helper'

describe 'users/data_downloads/index' do

  before(:each) do
    user = double(User)
    user.stub(:min_curator_level?) { false }
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_language) { Language.default }
    view.stub(:current_user) { user }
    assign(:background_processes, [])
    atttribute_known_uri = double(KnownUri)
    atttribute_known_uri.stub(:name) { 'Attributename' }
    atttribute_known_uri.stub(:uri) { 'AttributeUri' }
    @taxon_concept = double(TaxonConcept)
    @taxon_concept.stub(:id) { 1234 }
    @taxon_concept.stub(:title_canonical_italicized) { 'TaxonName' }
    @data_search_file = double(DataSearchFile)
    @data_search_file.stub(:complete?) { true }
    @data_search_file.stub(:known_uri) { atttribute_known_uri }
    @data_search_file.stub(:uri) { atttribute_known_uri.uri }
    @data_search_file.stub(:q) { nil }
    @data_search_file.stub(:from) { nil }
    @data_search_file.stub(:to) { nil }
    @data_search_file.stub(:updated_at) { Time.now }
    @data_search_file.stub(:completed_at) { Time.now }
    @data_search_file.stub(:expires_at) { @data_search_file.completed_at + DataSearchFile::EXPIRATION_TIME }
    @data_search_file.stub(:expired?) { false }
    @data_search_file.stub(:downloadable?) { true }
    @data_search_file.stub(:user) { user }
    @data_search_file.stub(:hosted_file_url) { 'http://where.we.host/downloads' }
    @data_search_file.stub(:unit_uri) { nil }
    @data_search_file.stub(:row_count) { 9870 }
    @data_search_file.stub(:sort) { 'asc' }
    @data_search_file.stub(:taxon_concept) { nil }
    @data_search_file.stub(:taxon_concept_id) { nil }
  end

  it 'should say when there are no saved searches' do
    render
    expect(rendered).to include(I18n.t('users.data_downloads.empty', data_search_url: data_search_url))
    expect(rendered).not_to include('Taxon group:.*TaxonName')
  end

  it 'should not say there are no saved searches if there are some' do
    assign(:background_processes, [ @data_search_file ])
    render
    expect(rendered).not_to include(I18n.t('users.data_downloads.empty', data_search_url: data_search_url))
  end

  context 'Basic Download' do
    it 'should show the basic info' do
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to have_tag('a', text: 'Attributename')
      expect(rendered).to have_tag('a', text: 'search again')
      expect(rendered).to_not include('Taxon group:.*TaxonName')
      expect(rendered).to_not include('Lowest value')
      expect(rendered).to_not include('Highest value')
    end

    it 'should show the taxon filter' do
      @data_search_file.stub(:taxon_concept) { @taxon_concept }
      @data_search_file.stub(:taxon_concept_id) { @taxon_concept.id }
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to match /Taxon group:.*TaxonName/
    end

    it 'should show the lowest value' do
      @data_search_file.stub(:from) { 1000 }
      @data_search_file.stub(:from_as_data_point) { DataPointUri.new(object: 1000) }
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to match /Lowest value:.*1,000/m
    end

    it 'should show the highest value' do
      @data_search_file.stub(:to) { 1000 }
      @data_search_file.stub(:to_as_data_point) { DataPointUri.new(object: 1000) }
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to match /Highest value:.*1,000/m
    end
  end

  context 'Pending Downloads' do
    it 'should show info specific to pending downloads' do
      @data_search_file.stub(:complete?) { false }
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to have_tag('span', text: 'processing')
      expect(rendered).to have_tag('li.pending')
      expect(rendered).to_not have_tag('a', text: 'delete')
      expect(rendered).to_not have_tag('a', text: 'download')
      expect(rendered).to have_tag('a', text: 'search again')
      expect(rendered).to have_tag('a', text: 'cancel and delete')
      expect(rendered).to_not include('Completed:')
      expect(rendered).to include('Submitted:')
      expect(rendered).to_not include('Expires in:')
      expect(rendered).to_not include('Expired')
      expect(rendered).to_not include('Total results: 9,870')
    end
  end

  context 'Completed Downloads' do
    it 'should show info specific to completed downloads' do
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to_not have_tag('span', text: 'processing')
      expect(rendered).to_not have_tag('li.pending')
      expect(rendered).to have_tag('a', text: 'delete')
      expect(rendered).to have_tag('a', text: 'download')
      expect(rendered).to have_tag('a', text: 'search again')
      expect(rendered).to_not have_tag('a', text: 'cancel and delete')
      expect(rendered).to include('Completed:')
      expect(rendered).to_not include('Submitted:')
      expect(rendered).to include('Expires in:')
      expect(rendered).to_not include('Expired')
      expect(rendered).to include('Total results: 9,870')
    end
  end

  context 'Expired Downloads' do
    it 'should show info specific to pending downloads' do
      @data_search_file.stub(:expired?) { true }
      @data_search_file.stub(:downloadable?) { false }
      assign(:background_processes, [ @data_search_file ])
      render
      expect(rendered).to_not have_tag('span', text: 'processing')
      expect(rendered).to_not have_tag('li.pending')
      expect(rendered).to have_tag('a', text: 'delete')
      expect(rendered).to_not have_tag('a', text: 'download')
      expect(rendered).to have_tag('a', text: 'search again')
      expect(rendered).to_not have_tag('a', text: 'cancel and delete')
      expect(rendered).to include('Completed:')
      expect(rendered).to_not include('Submitted:')
      expect(rendered).to_not include('Expires in:')
      expect(rendered).to include('Expired')
      expect(rendered).to include('Total results: 9,870')
    end
  end

end
