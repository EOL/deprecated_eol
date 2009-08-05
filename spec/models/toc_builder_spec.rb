require File.dirname(__FILE__) + '/../spec_helper'

describe TocBuilder do
  
  before(:each) do
    Scenario.load :foundation
  end
  
  it "call #toc_for" do
    # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}])
    # tc = build_taxon_concept(:toc=> [{}, {}, {}, {}, {}])
    # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}])
    # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}], :bhl => [{}])
    tc = build_taxon_concept(:toc=> [
      {:toc_item => TocItem.overview}, 
      {:toc_item => TocItem.search_the_web}, 
      {:toc_item => TocItem.specialist_projects}, 
      {:toc_item => TocItem.bhl}
    ])

    # Just asserting an assumption about label ordering.
    tb = TocBuilder.new
    
    toc = tb.toc_for(tc.id)
    toc[0].label.should == "Overview"
    toc[1].label.should == "References and More Information"
    toc[2].label.should == "Biodiversity Heritage Library"
    toc[3].label.should == "Specialist Projects"
    toc[4].label.should == "Search the Web"
  end
  
end