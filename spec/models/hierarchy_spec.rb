require File.dirname(__FILE__) + '/../spec_helper'

# I have no idea how Hierarchy is supposed to behave ...
#
# We need schema documentation  :(
#
# For now, I'll guess that only a label is required.
#
# Hierarchy requires a lot of columns, some of which I simple don't understand:
#   >> Hierarchy.create :label => 'hi', :url => 'foo', :hierarchy_group_id => 1, :hierarchy_group_version => 0, :description => 'hi', :agent_id => 1
#
describe Hierarchy do

  it 'should have documentation!'

  # ... doesn't require *anything?*

  #it 'should require a label' do
  #  Hierarchy.build( :label => nil ).should_not be_valid
  #  Hierarchy.build( :label => 'Tree of Life 2009' ).should be_valid
  #end

  it 'should be easy to create HierarchyEntries'

  # i have no idea how to create HierarchyEntries without having to create 
  # a lot of additional dependencies

  it 'should be able to find the Encyclopedia of Life Curators hierarchy with #eol_curators' do
    contributors_hierarchy = Hierarchy.find_by_label('Encyclopedia of Life Contributors') || Hierarchy.gen(:label => 'Encyclopedia of Life Contributors')
    Hierarchy.eol_contributors.should == contributors_hierarchy
  end

end
