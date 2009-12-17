require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do 
  describe 'feed_comments' do 
    
    before(:all) do
      truncate_all_tables
      Scenario.load('foundation')
      @tc = build_taxon_concept()
    end
    
    it 'should find text data objects for feeds' do
      [nil, @tc.id].each do |tc_id|
        res = Comment.feed_comments(tc_id)
        res.class.should == Array
        res_type = res.map {|i| i.class}.uniq
        res_type.size.should == 1
        res_type[0].should == Comment
      end
    end
  
    
  end
end
