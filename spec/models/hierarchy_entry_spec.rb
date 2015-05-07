# encoding: utf-8
require "spec_helper"

describe HierarchyEntry do

  before :all do
    truncate_all_tables
    populate_tables(:visibilities)
  end

  it 'should know what is a species_or_below?' do
    # HE.rank_id cannot be NULL
    expect(HierarchyEntry.gen(rank_id: '0').species_or_below?).to eq(false)
    expect(HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: 'genus')).species_or_below?).to eq(false)
    # there are lots of ranks which are considered species or below
    expect(Rank.italicized_labels.length).to be >= 60
    Rank.italicized_labels[0..5].each do |rank_label|
      clear_rank_caches
      expect(HierarchyEntry.gen(rank: Rank.gen_if_not_exists(label: rank_label)).species_or_below?).to eq(true)
    end
  end
  
  describe ".destroy_everything" do
       
    it "should call 'destroy_all' for top_images" do
      subject.top_images.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for synonyms" do
      subject.synonyms.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for curator_activity_logs" do
      subject.curator_activity_logs.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for hierarchy_entry_moves" do
      subject.hierarchy_entry_moves.should_receive(:destroy_all)
      subject.destroy_everything
    end
    
    it "should call 'destroy_all' for refs" do
      subject.refs.should_receive(:destroy_all)
      subject.destroy_everything
    end
  end
  
  describe "#ancestors" do 
    before(:all) do 
      @hierarchy= Hierarchy.gen
      @parent_hierarchy_entry = HierarchyEntry.gen
      @hierarchy_entry = HierarchyEntry.gen(hierarchy: @hierarchy, parent_id:@parent_hierarchy_entry.id )
    end
    
    # after(:each) do 
      # @hierarchy_entry.ancestors
    # end

    it  "re-heals itself if the ancestors are empty"  do 
      expect(@hierarchy).to receive(:reindex)
      @hierarchy_entry.ancestors
    end

  end

end
