require "spec_helper"

describe ForumCategory do

  before(:all) do
    load_foundation_cache
  end

  it "should increment view orders" do
    ForumCategory.destroy_all
    ForumCategory.gen.view_order.should == 1
    ForumCategory.gen.view_order.should == 2
    # it should increment from the highest
    ForumCategory.last.update_attributes({ view_order: 99 })
    ForumCategory.gen.view_order.should == 100
  end

  it "should validate titles" do
    lambda { post = ForumCategory.gen(title: nil) }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumCategory.gen(title: "") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumCategory.gen(title: "  ") }.should raise_error(ActiveRecord::RecordInvalid)
    expect { post = ForumCategory.gen(title: "Title") }.not_to raise_error
  end

end
