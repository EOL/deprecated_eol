require File.dirname(__FILE__) + '/../spec_helper'

describe List do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @taxon_concept_1 = build_taxon_concept
    @taxon_concept_2 = build_taxon_concept
    @user = User.gen
    @community = Community.gen
    @list = List.gen
    @data_object = DataObject.gen
  end

  describe 'validations' do

    before(:all) do
      @another_community = Community.gen
      @another_user = User.gen
    end

    before(:each) do
      List.delete_all
    end

    it 'should be valid when only a community ID is specified' do
      l = List.new(:name => 'whatever', :community_id => @community.id)
      l.valid?.should be_true
    end

    it 'should be valid when only a user ID is specified' do
      l = List.new(:name => 'whatever', :user_id => @user.id)
      l.valid?.should be_true
    end

    it 'should be INVALID when a user AND a community are specified' do
      l = List.new(:name => 'whatever', :user_id => @user.id, :community_id => @community.id)
      l.valid?.should_not be_true
    end

    it 'should be INVALID when neither a user nor a community are specified' do
      l = List.new(:name => 'whatever')
      l.valid?.should_not be_true
    end

    it 'should be INVALID when the name is identical within the scope of a user' do
      List.gen(:name => 'A name', :user_id => @user.id)
      l = List.new(:name => 'A name', :user_id => @user.id)
      l.valid?.should_not be_true
    end

    it 'should be valid when the same name is used by another user' do
      List.gen(:name => 'Another name', :user_id => @another_user.id)
      l = List.new(:name => 'Another name', :user_id => @user.id)
      l.valid?.should be_true
    end

    it 'should be INVALID when the name is identical within the scope of ALL communities' do
      List.gen(:name => 'Something new', :community_id => @another_community.id, :user_id => nil)
      l = List.new(:name => 'Something new', :community_id => @community.id)
      l.valid?.should_not be_true
    end

    it 'should be INVALID when a community already has a list' do
      List.gen(:name => 'ka-POW!', :community_id => @community.id, :user_id => nil)
      l = List.new(:name => 'Entirely different', :community_id => @community.id)
      l.valid?.should_not be_true
    end

  end

  it 'should be able to add TaxonConcept list items' do
    list = List.gen
    list.add(@taxon_concept_1)
    list.list_items.last.object.should == @taxon_concept_1
  end

  it 'should be able to add User list items' do
    list = List.gen
    list.add(@user)
    list.list_items.last.object.should == @user
  end

  it 'should be able to add DataObject list items' do
    list = List.gen
    list.add(@data_object)
    list.list_items.last.object.should == @data_object
  end

  it 'should be able to add Community list items' do
    list = List.gen
    list.add(@community)
    list.list_items.last.object.should == @community
  end

  it 'should be able to add List list items' do
    list = List.gen
    list.add(@list)
    list.list_items.last.object.should == @list
  end

  it 'should NOT be able to add Agent items' do # Really, we don't care about Agents, per se, just "anything else".
    list = List.gen
    lambda { list.add(Agent.gen) }.should raise_error(EOL::Exceptions::InvalidListItemType)
  end

  describe '#create_community' do

    it 'should create the community with a list of taxon concepts (and ignore other types of list items)' do
      list = List.gen
      list.add(@taxon_concept_1)
      list.add(@taxon_concept_2)
      list.add(@user)
      community = list.create_community
      community.focus.list_items.map {|li| li.object_id }.include?(@taxon_concept_1.id).should be_true
      community.focus.list_items.map {|li| li.object_id }.include?(@taxon_concept_2.id).should be_true
      community.focus.list_items.each do |li|
        li.object_type.should == "TaxonConcept"
      end
    end

    it 'should FAIL if the list has no taxon concepts' do
      list = List.gen
      list.add(@user)
      lambda { list.create_community }.should raise_error(EOL::Exceptions::CannotCreateCommunityWithoutTaxaInList)
    end

  end

  it 'should be able to find published lists in a search'

  it 'should NOT be able to find UN-published lists in a search'

  it 'should be #like-able and send notification to the owner'

end
