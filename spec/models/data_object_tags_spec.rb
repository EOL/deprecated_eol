require File.dirname(__FILE__) + '/../spec_helper'

describe DataObjectTags do

  before(:all) do
    Scenario.load :foundation
  end

  describe '#curator_activity_flag' do
    
    before(:each) do
      @taxon_concept = build_taxon_concept
      @data_object   = @taxon_concept.images.last
      @user          = @taxon_concept.acting_curators.to_a.last
      @dato_tags     = DataObjectTags.gen(:data_object => @data_object,
                                          :user => @user)
    end
    
    it 'should create a new LastCuratedDate pointing to the right TC and user' do
      num_lcd = LastCuratedDate.count
      @dato_tags.curator_activity_flag
      LastCuratedDate.count.should == num_lcd + 1
      LastCuratedDate.last.taxon_concept_id.should == @taxon_concept.id
      LastCuratedDate.last.user_id.should == @user.id
    end
    
    it 'should do nothing if the current user cannot curate this DataObject' do
      num_lcd = LastCuratedDate.count
      new_user   = User.gen
      @dato_tags = DataObjectTags.gen(:data_object => @data_object,
                                      :user => new_user)
      @dato_tags.curator_activity_flag
      LastCuratedDate.count.should_not == num_lcd + 1
    end
    
  end

end