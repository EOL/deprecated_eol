require File.dirname(__FILE__) + '/../spec_helper'


describe 'Data/TraitBank search' do

  it "should do many many things"

  it "should select attribute that was searched on"

  context "when selected taxon group is not searchable" do
    it "should perform search without taxon group"
    it "should tell the user that taxon group was removed from search"
    it "should not show taxon group in taxon name field"
  end

  context "when selected taxon group is searchable" do
    it "should perform search with taxon filter"
    it "should not tell users that taxon group was removed from search"
    it "should show taxon group in taxon name field"
  end

end
