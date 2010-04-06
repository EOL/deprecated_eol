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
          {:toc_item => TocItem.overview}
        ],
        :bhl => [{}, {}],
        :biomedical_terms => true, # The LigerCat entry.
        :images => [],  # this just speeds things up
        :comments => [] # this also speeds things up a bit.
      )
      
      user = User.create_new
      user.vetted = false
      
      # In order to get specialist projects, we need a mapping realted to one of the tc's names.
      Mapping.gen(:name => Name.last) # Cheating.  I know that the last name built was created for this TC

      # Literature References will be added if there is a reference to this TC:
      RefsTaxon.gen(:taxon => tc.entry.taxa.first)

      # Just asserting an assumption about label ordering.
      tb = TocBuilder.new
      
      toc = tb.toc_for(tc, :user => user)
      toc[0].label.should == "Overview"
      toc[1].label.should == "Names and Taxonomy"
      toc[2].label.should == "Synonyms"
      toc[3].label.should == "Biodiversity Heritage Library"
      toc[4].label.should == "References and More Information"
      toc[5].label.should == "Literature References"
      toc[6].label.should == "Specialist Projects"
      toc[7].label.should == "Biomedical Terms"
      toc[8].label.should == "Search the Web"
    end

  end
    
end
