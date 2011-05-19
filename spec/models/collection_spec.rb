require File.dirname(__FILE__) + '/../spec_helper'

describe Collection do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @taxon_concept_1 = build_taxon_concept
    @taxon_concept_2 = build_taxon_concept
    @user = User.gen
    @community = Community.gen
    @collection = Collection.gen
    @data_object = DataObject.gen
  end

  describe 'validations' do

    before(:all) do
      @another_community = Community.gen
      @another_user = User.gen
    end

    before(:each) do
      Collection.delete_all
    end

    it 'should be valid when only a community ID is specified' do
      l = Collection.new(:name => 'whatever', :community_id => @community.id)
      l.valid?.should be_true
    end

    it 'should be valid when only a user ID is specified' do
      l = Collection.new(:name => 'whatever', :user_id => @user.id)
      l.valid?.should be_true
    end

    it 'should be INVALID when a user AND a community are specified' do
      l = Collection.new(:name => 'whatever', :user_id => @user.id, :community_id => @community.id)
      l.valid?.should_not be_true
    end

    it 'should be INVALID when neither a user nor a community are specified' do
      l = Collection.new(:name => 'whatever')
      l.valid?.should_not be_true
    end

    it 'should be INVALID when the name is identical within the scope of a user' do
      Collection.gen(:name => 'A name', :user_id => @user.id)
      l = Collection.new(:name => 'A name', :user_id => @user.id)
      l.valid?.should_not be_true
    end

    it 'should be valid when the same name is used by another user' do
      Collection.gen(:name => 'Another name', :user_id => @another_user.id)
      l = Collection.new(:name => 'Another name', :user_id => @user.id)
      l.valid?.should be_true
    end

    it 'should be INVALID when the name is identical within the scope of ALL communities' do
      Collection.gen(:name => 'Something new', :community_id => @another_community.id, :user_id => nil)
      l = Collection.new(:name => 'Something new', :community_id => @community.id)
      l.valid?.should_not be_true
    end

    it 'should be INVALID when a community already has a collection' do
      Collection.gen(:name => 'ka-POW!', :community_id => @community.id, :user_id => nil)
      l = Collection.new(:name => 'Entirely different', :community_id => @community.id)
      l.valid?.should_not be_true
    end

  end

  it 'should be able to add TaxonConcept collection items' do
    collection = Collection.gen
    collection.add(@taxon_concept_1)
    collection.collection_items.last.object.should == @taxon_concept_1
  end

  it 'should be able to add User collection items' do
    collection = Collection.gen
    collection.add(@user)
    collection.collection_items.last.object.should == @user
  end

  it 'should be able to add DataObject collection items' do
    collection = Collection.gen
    collection.add(@data_object)
    collection.collection_items.last.object.should == @data_object
  end

  it 'should be able to add Community collection items' do
    collection = Collection.gen
    collection.add(@community)
    collection.collection_items.last.object.should == @community
  end

  it 'should be able to add Collection collection items' do
    collection = Collection.gen
    collection.add(@collection)
    collection.collection_items.last.object.should == @collection
  end

  it 'should NOT be able to add Agent items' do # Really, we don't care about Agents, per se, just "anything else".
    collection = Collection.gen
    lambda { collection.add(Agent.gen) }.should raise_error(EOL::Exceptions::InvalidCollectionItemType)
  end

  describe '#create_community' do

    it 'should create the community' do
      collection = Collection.gen
      collection.add(@taxon_concept_1)
      collection.add(@taxon_concept_2)
      collection.add(@user)
      community = collection.create_community
      community.focus.collection_items.map {|li| li.object }.include?(@taxon_concept_1).should be_true
      community.focus.collection_items.map {|li| li.object }.include?(@taxon_concept_2).should be_true
      community.focus.collection_items.map {|li| li.object }.include?(@user).should be_true
    end

  end

  describe '#editable_by?' do

    before(:all) do
      @owner = User.gen
      @someone_else = User.gen
      @users_collection = Collection.gen(:user => @owner)
      @community = Community.gen
      @community.initialize_as_created_by(@owner)
      @community.add_member(@someone_else)
      @community_collection = Collection.create(
        :community_id => @community.id,
        :name => 'Nothing Else Matters',
        :published => false,
        :special_collection_id => nil)
    end

    it 'should be editable by the owner' do
      @users_collection.editable_by?(@owner).should be_true
    end

    it 'should NOT be editable by someone else' do
      @users_collection.editable_by?(@someone_else).should_not be_true
    end

    it 'should NOT be editable if a watch collection' do
      @owner.watch_collection.editable_by?(@owner).should_not be_true
    end

    it 'should NOT be editable if a focus collection' do
      @community.focus.editable_by?(@owner).should_not be_true
    end

    it 'should NOT be editable if the user cannot edit the community' do
      @community_collection.editable_by?(@someone_else).should_not be_true
    end

    it 'should be editable if the user can edit the community' do
      @community_collection.editable_by?(@owner).should be_true
    end

  end

  it 'should know when it is a focus list' do
    @collection.is_focus_list?.should_not be_true
    @community.focus.is_focus_list?.should be_true
  end

  it 'should be able to find published collections in a search'

  it 'should NOT be able to find UN-published collections in a search'

end
