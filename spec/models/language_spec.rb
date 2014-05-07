require "spec_helper"

describe Language do

  before(:each) do
    load_foundation_cache
  end

  it "should list iteself as a representative if there is no group" do
    l = Language.gen
    l.representative_language.should == l
    l.all_ids.should == [ l.id ]
  end

  it "should recognize language groups" do
    l1 = Language.gen(language_group_id: 1)
    l2 = Language.gen(language_group_id: 1)
    g = LanguageGroup.gen(representative_language: l1)
    
    l1.representative_language.should == l1
    l2.representative_language.should == l1
    l1.all_ids.should == [ l1.id, l2.id ]
    l2.all_ids.should == [ l1.id, l2.id ]
  end

end
