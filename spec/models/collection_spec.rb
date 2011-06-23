require File.dirname(__FILE__) + '/../spec_helper'

describe Collection do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data = EOL::TestInfo.load('collections')
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
      c = Collection.new(:name => 'whatever', :community_id => @test_data[:community].id)
      c.valid?.should be_true
    end

    it 'should be valid when only a user ID is specified' do
      c = Collection.new(:name => 'whatever', :user_id => @test_data[:user].id)
      c.valid?.should be_true
    end

    it 'should be INVALID when a user AND a community are specified' do
      c = Collection.new(:name => 'whatever', :user_id => @test_data[:user].id, :community_id => @test_data[:community].id)
      c.valid?.should_not be_true
    end

    it 'should be INVALID when neither a user nor a community are specified' do
      c = Collection.new(:name => 'whatever')
      c.valid?.should_not be_true
    end

    it 'should be INVALID when the name is identical within the scope of a user' do
      Collection.gen(:name => 'A name', :user_id => @test_data[:user].id)
      c = Collection.new(:name => 'A name', :user_id => @test_data[:user].id)
      c.valid?.should_not be_true
    end

    it 'should be valid when the same name is used by another user' do
      Collection.gen(:name => 'Another name', :user_id => @another_user.id)
      c = Collection.new(:name => 'Another name', :user_id => @test_data[:user].id)
      c.valid?.should be_true
    end

    it 'should be INVALID when the name is identical within the scope of ALL communities' do
      Collection.gen(:name => 'Something new', :community_id => @another_community.id, :user_id => nil)
      c = Collection.new(:name => 'Something new', :community_id => @test_data[:community].id)
      c.valid?.should_not be_true
    end

    it 'should be INVALID when a community already has a collection' do
      Collection.gen(:name => 'ka-POW!', :community_id => @test_data[:community].id, :user_id => nil)
      c = Collection.new(:name => 'Entirely different', :community_id => @test_data[:community].id)
      c.valid?.should_not be_true
    end

  end

  it 'should be able to add TaxonConcept collection items' do
    collection = Collection.gen
    collection.add(@test_data[:taxon_concept_1])
    collection.collection_items.last.object.should == @test_data[:taxon_concept_1]
  end

  it 'should be able to add User collection items' do
    collection = Collection.gen
    collection.add(@test_data[:user])
    collection.collection_items.last.object.should == @test_data[:user]
  end

  it 'should be able to add DataObject collection items' do
    collection = Collection.gen
    collection.add(@test_data[:data_object])
    collection.collection_items.last.object.should == @test_data[:data_object]
  end

  it 'should be able to add Community collection items' do
    collection = Collection.gen
    collection.add(@test_data[:community])
    collection.collection_items.last.object.should == @test_data[:community]
  end

  it 'should be able to add Collection collection items' do
    collection = Collection.gen
    collection.add(@test_data[:community])
    collection.collection_items.last.object.should == @test_data[:community]
  end

  it 'should NOT be able to add Agent items' do # Really, we don't care about Agents, per se, just "anything else".
    collection = Collection.gen
    lambda { collection.add(Agent.gen) }.should raise_error(EOL::Exceptions::InvalidCollectionItemType)
  end

  describe '#create_community' do

    it 'should create the community' do
      collection = Collection.gen
      collection.add(@test_data[:taxon_concept_1])
      collection.add(@test_data[:taxon_concept_2])
      collection.add(@test_data[:user])
      community = collection.create_community
      community.focus.collection_items.map {|li| li.object }.include?(@test_data[:taxon_concept_1]).should be_true
      community.focus.collection_items.map {|li| li.object }.include?(@test_data[:taxon_concept_2]).should be_true
      community.focus.collection_items.map {|li| li.object }.include?(@test_data[:user]).should be_true
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
    @test_data[:collection].is_focus_list?.should_not be_true
    @test_data[:community].focus.is_focus_list?.should be_true
  end

  it 'should be able to add/modify/remove description' do
    description = "Valid description"
    collection = Collection.gen(:name => 'A name', :description => description, :user_id => @test_data[:user].id)
    collection.description.should == description
    collection.description = "modified #{description}"
    collection.description.should == "modified #{description}"
    collection.description = ""
    collection.description.should be_blank
  end

  it 'should be able to find published collections in a search'

  it 'should NOT be able to find UN-published collections in a search'

end
