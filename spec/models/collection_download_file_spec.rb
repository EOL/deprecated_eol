require 'spec_helper'

describe CollectionDownloadFile do

  def test_and_reset_downloadable
    expect(@collection_file.downloadable?).to eq(false)
    @collection_file.completed_at = Time.now
    @collection_file.row_count = 10
    @collection_file.hosted_file_url = "something"
    expect(@collection_file.downloadable?).to eq(true)
  end

  before(:all) do
    ContentPartnerStatus.create_enumerated
    License.create_enumerated
    Vetted.create_enumerated
    Visibility.create_enumerated
    AgentRole.create_enumerated
    CuratorLevel.create_enumerated
    Activity.create_enumerated
    ChangeableObjectType.create_enumerated
    DataType.create_enumerated
    MimeType.create_enumerated
    
    TocItem.gen
    SpecialCollection.gen(:name => 'Watch')
    SynonymRelation.gen_if_not_exists(label: "synonym")
    @lang = Language.gen_if_not_exists(label: 'Scientific Name', iso_639_1: '', source_form: 'Scientific Name')
    Language.gen_if_not_exists(label: 'Unknown')
    contributors_hierarchy = Hierarchy.find_by_label('Encyclopedia of Life Contributors') || Hierarchy.gen(label: 'Encyclopedia of Life Contributors')
    
    taxon_concept = build_taxon_concept(hierarchy_entry: HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: 'species')), :canonical_form => 'cannonical form')
    @data_point_uris = []
    5.times do
      @data_point_uris << DataPointUri.gen(taxon_concept: taxon_concept)
    end
  end

  before(:each) do
    @collection_file = CollectionDownloadFile.gen
  end

  it 'should upload files' do
    @collection_file.hosted_file_url = nil
    ContentServer.should_receive(:upload_data_search_file).with(@collection_file.local_file_url, @collection_file.id).and_return({response:'download.csv.zip', error: nil})
    @collection_file.build_file(@data_point_uris, @lang)
    expect(@collection_file.hosted_file_url).to eq(Rails.configuration.hosted_dataset_path + 'download.csv.zip')
  end

  describe 'hosted_file_exists?' do
    it 'should return false if hosted_file_url is nil' do
      @collection_file.hosted_file_url = nil
      expect(@collection_file.hosted_file_exists?).to eq(false)
    end
    
    it 'should return true if url is accepted' do
      EOLWebService.should_receive('url_accepted?').with('http://works').and_return(true)
      @collection_file.hosted_file_url = 'http://works'
      expect(@collection_file.hosted_file_exists?).to eq(true)
    end
    
    it 'should return false if url is not accepted' do
      EOLWebService.should_receive('url_accepted?').with('http://doesnt').and_return(false)
      @collection_file.hosted_file_url = 'http://doesnt'
      expect(@collection_file.hosted_file_exists?).to eq(false)
    end
  end
  
  describe 'downloadable?' do
    it 'should be downloadable if all conditions are staisfied' do
      @collection_file.completed_at = Time.now
      @collection_file.row_count = 10
      @collection_file.hosted_file_url = "something"
      expect(@collection_file.downloadable?).to eq(true)
    end
    
    it 'should not be downloadable if completed at is nil' do
      @collection_file.completed_at = nil
      expect(@collection_file.downloadable?).to eq(false)
    end
    
    it 'should not be downloadable if row count = 0' do
      @collection_file.row_count = 0
      expect(@collection_file.downloadable?).to eq(false)
    end
    
    it 'should not be downloadable if hosted file url is nil' do
      @collection_file.hosted_file_url = nil
      expect(@collection_file.downloadable?).to eq(false)
    end
  end
  
end
