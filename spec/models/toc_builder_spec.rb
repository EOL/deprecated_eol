require File.dirname(__FILE__) + '/../spec_helper'

describe TocBuilder do
  
  before(:each) do
    Scenario.load :foundation
  end
  
  describe '#toc_for' do

    it "should build a typical list of toc entries" do
      # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}])
      # tc = build_taxon_concept(:toc=> [{}, {}, {}, {}, {}])
      # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}])
      # tc = build_taxon_concept(:toc=> [{:toc_item => TocItem.overview}], :bhl => [{}])
      tc = build_taxon_concept(
        :toc=> [
          {:toc_item => TocItem.overview}, 
          # TODO - these three are specified incorrectly.
          # Search the Web is only created when the user (specified in options) has vetted = false.
          # Specialist Projects is only when there are collections and mappings for the TC.
          # BHL is only when there are really BHL entries.  There is an argument to build_taxon_concept that allows
          # you to specify these directly.
          {:toc_item => TocItem.search_the_web}, 
          {:toc_item => TocItem.specialist_projects}, 
          {:toc_item => TocItem.bhl}
        ],
        :biomedical_terms => true, # The LigerCat entry.
        :images => [],  # this just speeds things up
        :comments => [] # this also speeds things up a bit.
      )

      # Just asserting an assumption about label ordering.
      tb = TocBuilder.new
      
      toc = tb.toc_for(tc)
      toc[0].label.should == "Overview"
      toc[1].label.should == "References and More Information"
      toc[2].label.should == "Biodiversity Heritage Library"
      toc[3].label.should == "Specialist Projects"
      toc[4].label.should == "Biomedical Terms"
      toc[5].label.should == "Search the Web"
    end

  end
    
end
