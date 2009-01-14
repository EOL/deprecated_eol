require File.dirname(__FILE__) + '/../spec_helper'

describe DataObjectTags do

  fixtures :roles

  it '#create_valid should be valid' do
    DataObjectTags.create_valid.should be_valid
  end

=begin
  # i don't see any usage of validates_existence_of and it *does* slow things down ... so we're not doing this right now ...
  it 'should require an existing data_object and data_object_tag' do
    DataObjectTags.new_valid( :data_object_id => 1, :data_object_tag_id => 1 ).should_not be_valid
    DataObject.create_valid
    DataObjectTags.new_valid( :data_object_id => 1, :data_object_tag_id => 1 ).should_not be_valid
    DataObjectTag.create_valid
    DataObjectTags.new_valid( :data_object_id => 1, :data_object_tag_id => 1 ).should be_valid
    DataObjectTag.destroy 1
    DataObjectTags.new_valid( :data_object_id => 1, :data_object_tag_id => 1 ).should_not be_valid
  end
=end

  # ... i would kinda like to be able to DataObjectTags.create :user => u, :tag => t, :object => do
  #
  # ... we're unlikely to actually call DataObjectTag.create often, so it's likely not worth making that work
  #
  # We're more likely to say @data_object.tag [tags] or something

  it 'should have a user' do
    @bob = User.create_valid
    @tag = DataObjectTag.create_valid
    @join = DataObjectTags.create_valid :user => @bob, :data_object_tag_id => @tag.id

    @join.should be_valid
    @join.user.should == @bob
    @bob.data_object_tags.should include(@join)
    @bob.tags.should include(@tag)
  end

  it 'should have a data_object' do
    @obj = DataObject.create_valid
    @tag = DataObjectTag.create_valid
    @join = DataObjectTags.create_valid :data_object_id => @obj.id, :data_object_tag_id => @tag.id

    @join.should be_valid
    @join.data_object.should == @obj
    @obj.data_object_tags.should include(@join)
    @obj.tags.should include(@tag)
  end

  it 'should define a minimum number of uses require for a tag to be public' do
    # see data_object_tagging for actual use of this field
    DataObjectTags::minimum_usage_count_for_public_tags.should_not be_nil # should have a default
    DataObjectTags::minimum_usage_count_for_public_tags.should == DataObjectTags::DEFAULT_MIN_USAGE_FOR_PUBLIC_TAGS # default to const
    DataObjectTags::minimum_usage_count_for_public_tags = 1234567
    DataObjectTags::minimum_usage_count_for_public_tags.should == 1234567
  end

end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: data_object_data_object_tags
#
#  id                 :integer(4)      not null, primary key
#  data_object_id     :integer(4)      not null
#  data_object_tag_id :integer(4)      not null
#  user_id            :integer(4)
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_object_data_object_tags
#
#  id                 :integer(4)      not null, primary key
#  data_object_id     :integer(4)      not null
#  data_object_tag_id :integer(4)      not null
#  user_id            :integer(4)

