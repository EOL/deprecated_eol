require 'spec_helper'

describe 'users/data_downloads/index' do

  let(:atttribute_known_uri) {
    kn = build_stubbed(:known_uri, uri: 'AttributeUri')
    kn.stub(:name) { 'Attributename' }
    kn
  }
  let(:taxon_concept) {
    tc = build_stubbed(:taxon_concept)
    tc.stub(:title_canonical_italicized) { 'TaxonName' }
    tc
  }
  let(:data_search_file) { build_stubbed(:data_search_file, known_uri: atttribute_known_uri) }
  let(:user) { build_stubbed(:user) }

  subject{ render }

  before(:each) do
    view.stub(:meta_open_graph_data) { {} }
    view.stub(:tweet_data) { {} }
    view.stub(:current_user) { user }
    view.stub(:able_to_edit_user?).and_return(true)
  end

  shared_examples_for 'all downloads' do
    it { expect(subject).to have_tag('a', text: 'Attributename') }
    it { expect(subject).to have_tag('a', text: 'search again') }
    it { expect(subject).to_not include('Taxon group:.*TaxonName') }
    it { expect(subject).to_not include('Lowest value') }
    it { expect(subject).to_not include('Highest value') }
  end

  context 'without downloads' do
    before(:each) do
      assign(:background_processes, [ ])
    end

    it { expect(subject).to include(I18n.t('users.data_downloads.empty', data_search_url: data_search_url)) }
    it { expect(subject).to_not include('Taxon group:.*TaxonName') }
  end

  context 'with downloads' do
    before(:each) do
      assign(:background_processes, [ data_search_file ])
    end

    it_should_behave_like 'all downloads'
    it { expect(subject).to_not include(I18n.t('users.data_downloads.empty', data_search_url: data_search_url)) }

    it 'shows taxon filters' do
      data_search_file.taxon_concept = taxon_concept
      assign(:background_processes, [ data_search_file ])
      render
      expect(rendered).to match /Taxon group:.*TaxonName/
    end

    it 'shows lowest values' do
      data_search_file.from = 1000
      assign(:background_processes, [ data_search_file ])
      render
      expect(rendered).to match /Lowest value:.*1,000/m
    end

    it 'shows highest values' do
      data_search_file.to = 1000
      assign(:background_processes, [ data_search_file ])
      render
      expect(rendered).to match /Highest value:.*1,000/m
    end
  end

  context 'pending downloads' do
    before(:each) do
      data_search_file.completed_at = nil
      assign(:background_processes, [ data_search_file ])
    end

    it_should_behave_like 'all downloads'
    it { expect(subject).to have_tag('span', text: 'processing') }
    it { expect(subject).to have_tag('li.pending') }
    it { expect(subject).to_not have_tag('a', text: 'delete') }
    it { expect(subject).to_not have_tag('a', text: 'download') }
    it { expect(subject).to have_tag('a', text: 'search again') }
    it { expect(subject).to have_tag('a', text: 'cancel and delete') }
    it { expect(subject).to_not include('Completed:') }
    it { expect(subject).to include('Submitted:') }
    it { expect(subject).to_not include('Expires in:') }
    it { expect(subject).to_not include('Expired') }
    it { expect(subject).to_not include("Total results: #{data_search_file.row_count}") }
  end

  context 'completed downloads' do
    before(:each) do
      data_search_file.completed_at = Time.now
      allow(data_search_file).to receive(:downloadable?) { true }
      assign(:background_processes, [ data_search_file ])
    end

    it_should_behave_like 'all downloads'
    it { expect(subject).to_not have_tag('span', text: 'processing') }
    it { expect(subject).to_not have_tag('li.pending') }
    it { expect(subject).to have_tag('a', text: 'delete') }
    it { expect(subject).to have_tag('a', text: 'download') }
    it { expect(subject).to have_tag('a', text: 'search again') }
    it { expect(subject).to_not have_tag('a', text: 'cancel and delete') }
    it { expect(subject).to include('Completed:') }
    it { expect(subject).to_not include('Submitted:') }
    it { expect(subject).to include('Expires in:') }
    it { expect(subject).to_not include('Expired') }
    it { expect(subject).to include("Total results: #{data_search_file.row_count}") }
  end

  context 'expired downloads' do
    before(:each) do
      # NOTE - I had to make this 1 minute ago instead of Time.now. ...I assume that's not a problem.
      data_search_file.completed_at = 1.minute.ago - DataSearchFile::EXPIRATION_TIME
      assign(:background_processes, [ data_search_file ])
    end

    it_should_behave_like 'all downloads'
    it { expect(subject).to_not have_tag('span', text: 'processing') }
    it { expect(subject).to_not have_tag('li.pending') }
    it { expect(subject).to have_tag('a', text: 'delete') }
    it { expect(subject).to_not have_tag('a', text: 'download') }
    it { expect(subject).to have_tag('a', text: 'search again') }
    it { expect(subject).to_not have_tag('a', text: 'cancel and delete') }
    it { expect(subject).to include('Completed:') }
    it { expect(subject).to_not include('Submitted:') }
    it { expect(subject).to_not include('Expires in:') }
    it { expect(subject).to include('Expired') }
    it { expect(subject).to include("Total results: #{data_search_file.row_count}") }
  end

end
