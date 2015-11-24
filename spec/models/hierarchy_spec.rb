require "spec_helper"

describe Hierarchy do
  before(:all) do
    load_foundation_cache
  end

  it 'should be able to find the Encyclopedia of Life Curators hierarchy with #eol_curators' do
    contributors_hierarchy = Hierarchy.find_by_label('Encyclopedia of Life Contributors') || Hierarchy.gen(label: 'Encyclopedia of Life Contributors')
    Hierarchy.eol_contributors.should == contributors_hierarchy
  end

  it "should return hierarchies in alphabetical order" do
    hieararchies = Hierarchy.browsable_by_label
    hieararchies.select { |h| !h.is_a?(Hierarchy) }.should == []
    hieararchies.size > 0
    labels = hieararchies.map { |h| h.label }
    labels.should == labels.sort
    ids = hieararchies.map { |h| h.id }
    ids.should_not == ids.sort
  end

  it "should return the taxonomy providers with browsable hierarchies" do
    browsable_hierarchies = Hierarchy.taxonomy_providers.compact
    browsable_hierarchies.size.should > 1
    browsable_hierarchies.map { |h| h.label }.include?($DEFAULT_HIERARCHY_NAME).should be_true
  end

  it "should return current default hieararchy" do
    Hierarchy.default.should == Hierarchy.find_by_label($DEFAULT_HIERARCHY_NAME)
  end

  it "should return Species 2000 from 2007 which was the first default hierarchy for EOL" do
    Hierarchy.original.label.should ==  "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007"
  end

  it "should return EOL contribuors Hierarchy" do
    Hierarchy.eol_contributors.label.should == "Encyclopedia of Life Contributors"
  end

  it "should find NCBI taxonomies hierarchies sorted by group" do
    ncbi = Hierarchy.ncbi
    ncbi.label.should == "NCBI Taxonomy"
    all_ncbi = Hierarchy.all.select {|n| n.label == "NCBI Taxonomy"}.sort_by(&:hierarchy_group_version)
    all_ncbi.size.should >= 1
    all_ncbi.last.hierarchy_group_version.should == ncbi.hierarchy_group_version #highest hierarchy_group_version
  end

  it "returns all browsable hierarchies for a taxon concept" do
    taxon_concept = build_taxon_concept(comments: [], bhl: [], toc: [], images: [], flash: [], youtube: [])
    hierarchies = Hierarchy.browsable_for_concept(taxon_concept)
    hierarchies.size.should == 1
    hierarchies[0].id.should == Hierarchy.default.id
  end

  it "should return descriptive label, if exists, the label otherwise" do
    no_desc_label = Hierarchy.gen(label: "H1")
    desc_label = Hierarchy.gen(label: "H2", descriptive_label: "Decscriptive label")
    no_desc_label.form_label.should == "H1"
    desc_label.form_label.should ==  "Decscriptive label"
  end

  describe "#reindex" do
    before(:all) do
      @hierarchy = Hierarchy.gen
    end

    it " enqueues the Hierachy to be reindexed" do
      expect(HierarchyReindexing).to receive(:enqueue).with(@hierarchy)
      @hierarchy.reindex
    end
  end

  describe "#unpublish" do
    it "should unpublish published hierarchy entries "
    # NOTE: I would just do two of them, here
    it "should hide visible hierarchy entries"
    # Again, two. NOTE that "hide" means "make invisible"
    it "should unpublish published synonyms"
    it "should return an array of affected entries"
  end

  # let(:hierarchy) { Hierarchy.find_by_label($DEFAULT_HIERARCHY_NAME) }
  #
  # it "should return kingdoms of the hierarchy sorted by default by scientific names" do
  #   #TODO fix this one, sometimes it does not work
  #   # kingdoms = hierarchy.kingdoms
  #   # parent_ids = kingdoms.map(&:parent_id).uniq
  #   # parent_ids.size.should == 1
  #   # parent_ids[0].should == 0
  #   # names = kingdoms.map { |k| k.name($DEFAULT_EXPERTISE, Language.english) }
  #   # names.should == names.sort
  # end
  #
  # it "should return kingdoms sorted by common name in a particular language" do
  # end
  #
  # describe "#kingdoms_hash(detail_level = :middle, language = Language.english)" do
  # end
  #
  # describe "#kingdom_details(params = {})" do
  # end
  #
  # describe "#node_to_hash(node, detail_level)" do
  #
  # end
  # describe "#attribution" do
  # end

end
