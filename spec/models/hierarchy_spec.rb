require File.dirname(__FILE__) + '/../spec_helper'

describe Hierarchy do

  it 'should be able to find the Encyclopedia of Life Curators hierarchy with #eol_curators' do
    contributors_hierarchy = Hierarchy.find_by_label('Encyclopedia of Life Contributors') || Hierarchy.gen(:label => 'Encyclopedia of Life Contributors')
    Hierarchy.eol_contributors.should == contributors_hierarchy
  end

end
