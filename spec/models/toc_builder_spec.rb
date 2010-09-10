require File.dirname(__FILE__) + '/../spec_helper'

describe TocBuilder do
  
  before(:each) do
    truncate_all_tables
    load_foundation_cache
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
      
      # In order to get content_partners, we need a mapping realted to one of the tc's names.
      HierarchyEntry.gen(:hierarchy => Hierarchy.last, :taxon_concept => TaxonConcept.last, :source_url => 'something') # Cheating.  I know that the last name built was created for this TC

      # Literature References will be added if there is a reference to this TC:
      HierarchyEntriesRef.gen(:hierarchy_entry => tc.entry)

      # Just asserting an assumption about label ordering.
      tb = TocBuilder.new
      
      toc = tb.toc_for(tc, :user => user)
      toc[0].label.should == "Overview"
      toc[1].label.should == "Names and Taxonomy"
      toc[2].label.should == "Synonyms"
      toc[3].label.should == "Page Statistics"
      toc[4].label.should == "Content Summary"
      toc[5].label.should == "Biodiversity Heritage Library"
      toc[6].label.should == "References and More Information"
      toc[7].label.should == "Literature References"
      toc[8].label.should == "Content Partners"
      toc[9].label.should == "Biomedical Terms"
      toc[10].label.should == "Search the Web"
    end

  end
    
end
