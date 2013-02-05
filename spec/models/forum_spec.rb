require File.dirname(__FILE__) + '/../spec_helper'

describe Forum do

  before(:all) do
    load_foundation_cache
  end

  it "should increment view orders within a category" do
    forum1 = Forum.gen
    forum1.view_order.should == 1
    Forum.gen(:forum_category => forum1.forum_category).view_order.should == 2
    # it should increment from the highest
    Forum.last.update_attributes({ :view_order => 99 })
    Forum.gen(:forum_category => forum1.forum_category).view_order.should == 100
    Forum.gen.view_order.should == 1
  end

  it "should validate names" do
    lambda { post = Forum.gen(:name => nil) }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = Forum.gen(:name => "") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = Forum.gen(:name => "  ") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = Forum.gen(:name => "Name") }.should_not raise_error(ActiveRecord::RecordInvalid)
  end

end
