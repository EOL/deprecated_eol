require File.dirname(__FILE__) + '/../spec_helper'

describe DataObjectTag do

  it '#new_valid should be valid' do
    DataObjectTag.new_valid.should be_valid
  end
  
  DataObjectTag.valid_attributes.keys.each do |attribute|
    it "should require #{attribute}" do
      DataObjectTag.new_valid({ attribute => nil }).should_not be_valid
    end
  end

  it 'should require a unique key / value pair' do
    DataObjectTag.create_valid( :key => 'foo', :value => 'bar' ).should be_valid
    DataObjectTag.create_valid( :key => 'foo', :value => 'bar' ).should_not be_valid
    DataObjectTag.create_valid( :key => 'foo', :value => 'bacon' ).should be_valid
  end

  it 'DataObjectTag keys can be no longer than 30 characters' do
    DataObjectTag.new_valid( :key => ('x' * 30) ).should be_valid
    DataObjectTag.new_valid( :key => ('x' * 31) ).should_not be_valid
    DataObjectTag.new_valid( :key => ('x' * 31) ).should have(1).errors_on(:key)
  end

  it 'should be public or private (with pretty alias methods)' do
    DataObjectTag.new_valid(:is_public => true).is_public.should  == true
    DataObjectTag.new_valid(:is_public => false).is_public.should == false

    DataObjectTag.new_valid(:is_public => true).is_public?.should  == true
    DataObjectTag.new_valid(:is_public => false).is_public?.should == false

    DataObjectTag.new_valid(:is_public => true).public?.should  == true
    DataObjectTag.new_valid(:is_public => false).public?.should == false
  end

  it 'should give suggestions for how to complete a partially typed key' do
    lambda {
      %w( color habitat colony colors ).each do |key|
        DataObjectTag.create_valid :key => key
      end
    }.should change(DataObjectTag, :count).by(4)

    DataObjectTag.suggest_key('co',nil,false).should    == %w( colony color colors ) # alphabetized
    DataObjectTag.suggest_key('color',nil,false).should == %w( color colors ) # alphabetized
    DataObjectTag.suggest_key('x',nil,false).should     == []
  end

  it "#suggest_key should accept pre-cached data to use for querying" do
    %w( color habitat colony colors ).each do |key|
      DataObjectTag.create_valid :key => key
    end
    tags = DataObjectTag.find :all
    DataObjectTag.delete_all
    DataObjectTag.count.should == 0

    # should return suggestions using only the cached data (there aren't even any rows in the DB)
    DataObjectTag.suggest_key('co', tags).should    == %w( colony color colors ) # alphabetized
    DataObjectTag.suggest_key('color', tags).should == %w( color colors ) # alphabetized
    DataObjectTag.suggest_key('x', tags).should     == []
  end

  it 'should give suggestions for how to complete a partially typed value' do
    %w( red green blue blurp blarp ).each do |color|
      DataObjectTag.create :key => 'color', :value => color
    end

    DataObjectTag.suggest_value('g', :color, nil, false).should   == %w( green )
    DataObjectTag.suggest_value('bl', :color, nil, false).should  == %w( blarp blue blurp )
    DataObjectTag.suggest_value('blu', :color, nil, false).should == %w( blue blurp )
    DataObjectTag.suggest_value('x', :color, nil, false).should   == []
  end

  it "#suggest_value should accept pre-cached data to use for querying" do
    %w( red green blue blurp blarp ).each do |color|
      DataObjectTag.create :key => 'color', :value => color
    end
    %w( here there everywhere ).each do |place|
      DataObjectTag.create :key => 'place', :value => place
    end
    tags = DataObjectTag.find :all
    DataObjectTag.delete_all
    DataObjectTag.count.should == 0

    # should return suggestions using only the cached data (there aren't even any rows in the DB)
    DataObjectTag.suggest_value('g', :color, tags, false).should   == %w( green )
    DataObjectTag.suggest_value('bl', :color, tags, false).should  == %w( blarp blue blurp )
    DataObjectTag.suggest_value('blu', :color, tags, false).should == %w( blue blurp )
    DataObjectTag.suggest_value('x', :color, tags, false).should   == []
  end

  it 'should provide a shortcut for a finder method for getting all tags for a key' do
    %w( red green blue ).each do |color|
      DataObjectTag.create :key => 'color', :value => color
    end
    %w( here there everywhere ).each do |place|
      DataObjectTag.create :key => 'place', :value => place
    end

    DataObjectTag[:color].should  == DataObjectTag.ordered.find_all_by_key('color')
    DataObjectTag['color'].should == DataObjectTag.ordered.find_all_by_key('color')
  end

  it 'should provide a shortcut for a finder method for getting a tag by key + value' do
    %w( red green blue ).each do |color|
      DataObjectTag.create :key => 'color', :value => color
    end

    DataObjectTag[:color, :red].should        == DataObjectTag.find_by_key_and_value('color','red')
    DataObjectTag['color', 'blue'].should     == DataObjectTag.find_by_key_and_value('color','blue')
    DataObjectTag['color', 'no exist'].should == DataObjectTag.find_by_key_and_value('color','no exist')
  end

end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: data_object_tags
#
#  id                :integer(4)      not null, primary key
#  is_public         :boolean(1)
#  key               :string(255)     not null
#  total_usage_count :integer(4)
#  value             :string(255)     not null
#  created_at        :datetime
#  updated_at        :datetime
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_object_tags
#
#  id                :integer(4)      not null, primary key
#  is_public         :boolean(1)
#  key               :string(255)     not null
#  total_usage_count :integer(4)
#  value             :string(255)     not null
#  created_at        :datetime
#  updated_at        :datetime

