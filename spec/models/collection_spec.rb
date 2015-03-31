require "spec_helper"

class CollectionBuilder

  @@taxa_for_collections = []

  def self.gen(opts = {})
    col = Collection.gen
    if opts[:taxa] && ( ! defined?(@@taxa_for_collections) || @@taxa_for_collections.size <= opts[:taxa])
      while @@taxa_for_collections.size < opts[:taxa] do
        @@taxa_for_collections << FactoryGirl.build_stubbed(TaxonConcept)
      end
    end
    if opts[:taxa]
      (0..opts[:taxa]).each do |i|
        col.add(@@taxa_for_collections[i])
      end
    end
    if opts[:featured]
      @@community_for_featuring ||= Community.gen
      @@community_for_featuring.collection.add(col)
    end
    opts[:users].times { col.add(User.gen) }
    col
  end

end

describe Collection do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    collections = {}
    collections[:taxon_concept_1] = TaxonConcept.gen
    collections[:user] = User.gen
    collections[:community] = Community.gen
    collections[:collection] = Collection.gen
    collections[:collection].users = [collections[:user]]
    collections[:data_object] = DataObject.last
    @test_data = collections
  end

  describe 'validations' do

    before(:all) do
      @another_community = Community.gen
      @another_user = User.gen
    end

    before(:each) do
      Collection.delete_all
    end

    it 'should be valid when the same name is used by another user' do
      c = Collection.gen(name: 'Another name')
      c.users = [@another_user]
      c = Collection.new(name: 'Another name')
      c.users = [@test_data[:user]]
      c.valid?.should be_true
    end

  end

  it 'should be able to add TaxonConcept collection items' do
    collection = Collection.gen
    collection.add(@test_data[:taxon_concept_1])
    collection.collection_items.last.collected_item.should == @test_data[:taxon_concept_1]
  end

  it 'should be able to add User collection items' do
    collection = Collection.gen
    collection.add(@test_data[:user])
    collection.collection_items.last.collected_item.should == @test_data[:user]
  end

  it 'should be able to add DataObject collection items' do
    collection = Collection.gen
    collection.add(@test_data[:data_object])
    collection.collection_items.last.collected_item.should == @test_data[:data_object]
  end

  it 'should be able to add Community collection items' do
    collection = Collection.gen
    collection.add(@test_data[:community])
    collection.collection_items.last.collected_item.should == @test_data[:community]
  end

  it 'should be able to add Collection collection items' do
    collection = Collection.gen
    collected = Collection.gen
    collection.add(collected)
    collection.collection_items.last.collected_item.should == collected
  end

  it 'should NOT be able to add Agent items' do # Really, we don't care about Agents, per se, just "anything else".
    collection = Collection.gen
    lambda { collection.add(Agent.gen) }.should raise_error(EOL::Exceptions::InvalidCollectionItemType)
  end

  describe '#editable_by?' do

    before(:all) do
      @owner = User.gen
      @someone_else = User.gen
      @users_collection = Collection.gen
      @users_collection.users = [@owner]
      @community = Community.gen
      @community.initialize_as_created_by(@owner)
      @community.add_member(@someone_else)
      @community_collection = Collection.create(
        name: 'Nothing Else Matters',
        published: false,
        special_collection_id: nil)
      @community.collections = [@community_collection]
    end

    it 'should be editable by the owner' do
      @users_collection.editable_by?(@owner).should be_true
    end

    it 'should NOT be editable by someone else' do
      @users_collection.editable_by?(@someone_else).should_not be_true
    end

    it 'should NOT be editable if the user cannot edit the community' do
      @community_collection.editable_by?(@someone_else).should_not be_true
    end

    it 'should be editable if the user can edit the community' do
      @community_collection.editable_by?(@owner).should be_true
    end

  end

  it 'should know when it is a focus list' do
    @test_data[:collection].is_focus_list?.should_not be_true
    collection = Collection.gen
    Community.gen(collections: [collection])
    expect(collection.is_focus_list?).to be true
  end

  it 'should know when it is a focus collection' do
    focus = Community.gen.collections.first
    focus.focus?.should be_true
    nonfocus = Collection.gen
    nonfocus.focus?.should_not be_true
  end

  it 'should be able to add/modify/remove description' do
    description = "Valid description"
    collection = Collection.gen(name: 'A name', description: description)
    collection.users = [@test_data[:user]]
    collection.description.should == description
    collection.description = "modified #{description}"
    collection.description.should == "modified #{description}"
    collection.description = ""
    collection.description.should be_blank
  end

  it 'should be able to find collections that contain an object' do
    collection = Collection.gen
    user = User.gen
    collection.add user
    Collection.which_contain(user).should == [collection]
  end

  it 'should get taxon counts for multiple collections' do
    collection_1 = CollectionBuilder.gen(taxa: 1, users: 1)
    collection_2 = CollectionBuilder.gen(taxa: 2, users: 1)
    collection_3 = CollectionBuilder.gen(taxa: 3, users: 1)
    collections = [collection_1, collection_2, collection_3]
    taxa_counts = Collection.get_taxa_counts(collections)
    taxa_counts[collections[0].id].should == 1
    taxa_counts[collections[1].id].should == 2
    taxa_counts[collections[2].id].should == 3
  end

  it 'should be able to set relevance by background calculation' do
    col = Collection.gen
    Resque.should_receive(:enqueue).with(CollectionRelevanceCalculator, col.id)
    col.set_relevance
  end

  it 'should know what its default view style is' do
    collection = Collection.gen
    collection.view_style_or_default.should == ViewStyle.annotated
    collection.update_attributes(view_style: ViewStyle.gallery)
    collection.reload
    collection.view_style_or_default.should == ViewStyle.gallery
  end

  it '#inaturalist_project_info should call InaturalistProjectInfo' do
    collection = Collection.gen
    InaturalistProjectInfo.should_receive(:get).with(collection.id)
    collection.inaturalist_project_info
  end

  it 'should give a unique list of maintained_by' do
    collection = Collection.gen
    user = User.gen
    community = Community.gen
    2.times { collection.users << user }
    2.times { collection.communities << community }
    collection.maintained_by.length.should == 2
    collection.maintained_by.should include(user)
    collection.maintained_by.should include(community)
  end

  it '#taxa returns taxa collection_items' do
    collection = Collection.gen
    items = []
    items.should_receive(:taxa).and_return(["this"])
    collection.should_receive(:collection_items).and_return(items)
    expect(collection.taxa).to eq(["this"])
  end

  it '#taxa_count counts taxa' do
    collection = Collection.gen
    collection.should_receive(:taxa).and_return([1,2,3])
    expect(collection.taxa_count).to eq(3)
  end

  it 'has a default image' do
    collection = Collection.gen(logo_file_name: '', logo_cache_url: nil)
    expect(collection.logo_url).to eq("v2/logos/collection_default.png")
  end

  it 'calls ImageManipulation to get image name' do
    #cache_url doesn't matter here, but cannot be nil:
    collection = Collection.gen(logo_file_name: 'this.ext', logo_cache_url: 1)
    allow(ImageManipulation).to receive(:local_file_name) { "hithere" }
    expect(collection.logo_url).to match /hithere/
    expect(ImageManipulation).to have_received(:local_file_name).with(collection)
  end

  context 'when using content server for thumbnails' do

    before do
      Rails.configuration.use_content_server_for_thumbnails = true
    end

    # TODO - can we *ensure* this runs?
    after do
      Rails.configuration.use_content_server_for_thumbnails = false
    end

    it 'uses 88x88 image cache for small icons' do
      image_cache = Faker::Eol.image
      collection = Collection.gen(logo_cache_url: image_cache)
      allow(DataObject).to receive(:image_cache_path) { "helloagain" }
      expect(collection.logo_url(size: :small)).to match /helloagain/
      # TODO - this is a little fragile... we know too much when we specify the arguments, here, but I really want to check the 88x88:
      expect(DataObject).to have_received(:image_cache_path).with(image_cache, '88_88', specified_content_host: nil)
    end

    it 'uses 130x130 image cache' do
      image_cache = Faker::Eol.image
      collection = Collection.gen(logo_cache_url: image_cache)
      allow(DataObject).to receive(:image_cache_path) { "suchfun" }
      expect(collection.logo_url).to match /suchfun/
      # TODO - this is a little fragile... we know too much when we specify the arguments, here, but I really want to check the 130:
      expect(DataObject).to have_received(:image_cache_path).with(image_cache, '130_130', specified_content_host: nil)
    end

  end

  describe "#unpublish" do

    let(:collection) { Collection.gen }

    it "calls #remove_from_index" do
      allow(collection).to receive(:remove_from_index)
      collection.unpublish
      expect(collection).to have_received(:remove_from_index)
    end

  end


  it 'has other unimplemented tests but I will not make them all pending, see the spec file'
  # should know when it is "special" TODO - do we need this anymore?  I don't think so...
  # should know when it is a resource collection.
  # should know when it is maintained by a user
  # should know when it is maintained by a community
  # should know if it has an item.
  # should default to the SortStyle#newest for #sort_style, or use its own value
  # should call EOL::Solr::CollectionItems.search_with_pagination with sort style to get #items_from_solr.
  # should call EOL::Solr::CollectionItems.get_facet_counts to get #facet_counts.
  # should call EOL::Solr::CollectionItems.get_facet_counts to get #facet_count by type.
  # should know when it is a watch collection

end
