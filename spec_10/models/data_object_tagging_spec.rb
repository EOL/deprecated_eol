require File.dirname(__FILE__) + '/../spec_helper'

describe DataObject, 'tagging' do

  fixtures :roles

  before do
    @data_object = DataObject.create_valid
    @data_object.should be_valid
    @data_object.should_not be_a_new_record

    @bob = User.create_valid
    @bob.should be_valid
  end

  # NOTE so far, i can't get it to NOT allow keys/values containing newlines via regex - luckily, input text fields don't allow newlines
  it "keys and values should be alphanumeric with no punctuation or spaces (for now)" do
    [ :key, :value ].each do |key_or_value|
      [ 'some color', 'some.color', 'some,color', 'some:color', "some\tcolor", "h1!", "hi " ].each do |invalid|
        DataObjectTag.create_valid( key_or_value => invalid ).should_not be_valid
      end
      %w( some color 1234 foo1 1foo f89e798f ).each do |valid|
        DataObjectTag.create_valid( key_or_value => valid ).should be_valid
      end
    end
  end

  it '#tag key, value should tag a DataObject' do
    @data_object.tags.should be_empty
    @data_object.tag :color, 'red'
    @data_object.tags.should_not be_empty

    join = DataObjectTags.find_all_by_data_object_id(@data_object.id).first
    join.data_object.should == @data_object
    join.data_object_tag.key.should == 'color'
    join.data_object_tag.value.should == 'red'

    # test aliases too
    join.object.should == @data_object
    join.tag.key.should == 'color'
    join.tag.value.should == 'red'
  end

  it 'should only allow 1 unique tag per user (including a nil user)' do
    @data_object.tags.should be_empty
    
    @data_object.tag( :color, 'red' ).should be_true
    @data_object.tags.length.should == 1
    
    @data_object.tag( :color, 'red' ).should be_false
    @data_object.tags.length.should == 1
    
    @data_object.tag( :color, 'red', @bob ).should be_true
    @data_object.tags.length.should == 2
    
    @data_object.tag( :color, 'red', @bob ).should be_false
    @data_object.tags.length.should == 2

    @data_object.tag( :color, 'blue', @bob ).should be_true
    @data_object.tags.length.should == 3
  end

  it '#tag key, value, user should tag a DataObject for a particular user' do
    @data_object.tags.should be_empty
    @bob.tags.should be_empty

    @data_object.tag( :color, 'red', @bob ).should be_true
    @data_object.tags.length.should == 1
    DataObjectTags.find_all_by_user_id(@bob.id).length.should == 1
    @bob.tags.length.should == 1
    @bob.data_object_tags.length.should == 1
    @bob.data_object_tags.first.object.should == @data_object
    @bob.data_object_tags.first.tag.key.should == 'color'
    @bob.data_object_tags.first.tag.value.should == 'red'
  end

  # yes, this tests a LOT of stuff.  we setup some unique circumstances (public versus non-public tags)
  # so we test to make sure that everything works properly with regards to public versus non-public tags
  #
  # i should ***really*** split this spec up into smaller specs.  it tells a somewhat good (long) 'story,' though
  it 'private tags should show up as public after being used a certain number of times' do

    # set the minimum usage count to a low number so we don't make a million records
    DataObjectTags.should_receive(:minimum_usage_count_for_public_tags).any_number_of_times.and_return(3)

    # we need enough users to be able to tag enough to make a tag public
    users = []
    DataObjectTags::minimum_usage_count_for_public_tags.times do |i|
      users << User.create_valid!( :username => "BobSmith#{i}" )
    end

    # tag up to the point where we only need one more private tag for a tag to become 'public'
    users.each do |user|
      @data_object.tag( :color, :blue, user ).should be_true unless user == users.last
    end
    @data_object.tags.length.should == ( DataObjectTags::minimum_usage_count_for_public_tags - 1 )
    @data_object.public_tags.should be_empty
    DataObjectTags.public_tags_for_tag_key(:color).should be_empty
    DataObjectTag[:color, :blue].should_not be_public

    # add a public static tag 
    DataObjectTag.suggest_key('c').should be_empty
    DataObjectTag.suggest_key(' ').should be_empty
    DataObjectTag.suggest_value('r', :color).should_not include('red')
    DataObjectTag.create_valid! :key => 'color', :value => 'red', :is_public => true
    DataObjectTag.suggest_value('r', :color).should include('red')
    DataObjectTag.suggest_key('c').should include('color')
    # DataObjectTag.suggest_key(' ').should include('color') # it doesn't know what to do with this ... the controller should handle this, if we want this behavior

    # for for blue (shouldn't be there yet because it's not public yet)
    DataObjectTag.suggest_value('b', :color).should_not include('blue')
    DataObjectTag.suggest_value(' ', :color).should_not include('blue')

    # we've added 1 less tag than is necessary for it to become public ... let's add the last one!
    @data_object.tag( :color, :blue, users.last ).should be_true
    @data_object.tags.length.should == DataObjectTags::minimum_usage_count_for_public_tags
    @data_object.public_tags.length.should == 1
    @data_object.public_tags.first.should == DataObjectTag[:color, :blue]
    DataObjectTags.public_tags_for_tag_key(:color).length == 1
    DataObjectTags.public_tags_for_tag_key(:color).first.should == DataObjectTag[:color, :blue]
    DataObjectTag[:color, :blue].should be_public
    DataObjectTag.suggest_value('b', :color).should include('blue')
    DataObjectTag.suggest_value(' ', :color).should include('blue')
    DataObjectTag.suggest_value(' ', :color).should include('red')
    DataObjectTag.suggest_value(' ', :color).length.should == 2 # red and blue
    DataObjectTag.suggest_key('col').should include('color')

    # key should still be suggested after removing the static one
    DataObjectTag[:color,:red].destroy
    DataObjectTag[:color,:red].should be_nil
    DataObjectTag.suggest_key('col').should include('color')
    DataObjectTag.suggest_value(' ', :color).should_not include('red')
  end

  it '#public_tags should return only the public tags' do
    @data_object.tag( :color, 'red' ).should be_true # <--- won't be public anymore! ... not unless used X times ...
    @data_object.tag( :color, 'yellow', @bob ).should be_true
    @data_object.tag( :color, 'blue', @bob ).should be_true
    @data_object.tags.length.should == 3
    @data_object.public_tags.length.should == 0        # non-user-specific (not marked as public, so it won't be public!)
    @data_object.private_tags(@bob).length.should == 2 # bob's
  end

  # alias as user_tags and users_tags
  it "#private_tags(user) should return only a single user's tags for an object" do
    @data_object.tag( :color, 'yellow', @bob ).should be_true
    @data_object.tag( :color, 'blue', @bob ).should be_true

    @data_object.private_tags(@bob).length.should == 2 # bob's
    @data_object.user_tags(@bob).length.should == 2 # bob's
    @data_object.user_tags(@bob).length.should == 2 # bob's
  end

  # we should probably make a user_tagging_spec, but for now ...
  it "User#tags_for(object) should return a user's tags for an object" do
    @data_object.tag( :color, 'yellow', @bob ).should be_true
    @data_object.tag( :color, 'blue', @bob ).should be_true

    @bob.tags_for(@data_object).length.should == 2
    @bob.tags_for(@data_object).first.key.should == 'color'
    @bob.tags_for(@data_object).first.value.should == 'yellow'
  end

  it "User#tagged_objects should return all of the objects that a user has tagged" do
    @another_object = DataObject.create_valid :description => 'i am another object'
    @another_object.should be_valid

    @data_object.tag( :color, 'yellow', @bob ).should be_true
    @another_object.tag( :color, 'blue', @bob ).should be_true

    @bob.tagged_objects.length.should == 2
    @bob.tagged_objects.should include(@data_object)
    @bob.tagged_objects.should include(@another_object)
  end

end
