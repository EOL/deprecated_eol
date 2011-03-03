require File.dirname(__FILE__) + '/../spec_helper'

describe Ref do
  
  before(:all) do
    load_foundation_cache
    Factory(:toc_item, :label => "Literature Review")
    
    @tc_object_refs = Factory(:taxon_concept)
    @he_object_refs = []
    4.times do
      @he_object_refs << Factory(:hierarchy_entry, :taxon_concept => @tc_object_refs)
    end
    @he_object_refs.each do |he|
      2.times do
        d_o = Factory(:data_object)
        dohe = Factory(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
        ref = Factory(:ref)
        dor = Factory(:data_objects_ref, :data_object => d_o, :ref => ref)
      end
    end
    
    @tc_taxa_refs = Factory(:taxon_concept)
    @he_taxa_refs = []
    3.times do 
      @he_taxa_refs << Factory(:hierarchy_entry, :taxon_concept => @tc_taxa_refs)
    end
    @he_taxa_refs.each do |he|
      2.times do
        ref = Factory(:ref)
        Factory(:hierarchy_entries_ref, :ref => ref, :hierarchy_entry => he)
      end
    end
  end

  it "should have literature reviews when objects have references" do
    Ref.literature_references_for?(@tc_object_refs.id).should be_true
    Ref.find_refs_for(@tc_object_refs.id).size.should == 8
  end
  
  it "should have literature references when the reference is visible and published" do
    tc = Factory(:taxon_concept)
    he = Factory(:hierarchy_entry, :taxon_concept => tc)
    d_o = Factory(:data_object)
    dohe = Factory(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
    ref = Ref.gen(:full_reference => "doesnt matter", :published => 1, :visibility => Visibility.visible)
    dor = Factory(:data_objects_ref, :data_object => d_o, :ref => ref)
    Ref.literature_references_for?(tc.id).should be_true
    Ref.find_refs_for(tc.id).size.should == 1
  end
  
  it "should not have literature references when the reference is unpublished" do
    tc = Factory(:taxon_concept)
    he = Factory(:hierarchy_entry, :taxon_concept => tc)
    d_o = Factory(:data_object)
    dohe = Factory(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
    ref = Ref.gen(:full_reference => "doesnt matter", :published => 0, :visibility => Visibility.visible)
    dor = Factory(:data_objects_ref, :data_object => d_o, :ref => ref)
    Ref.literature_references_for?(tc.id).should_not be_true
    Ref.find_refs_for(tc.id).size.should == 0
  end
  
  it "should not have literature references when the reference is invisible" do
    tc = Factory(:taxon_concept)
    he = Factory(:hierarchy_entry, :taxon_concept => tc)
    d_o = Factory(:data_object)
    dohe = Factory(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
    ref = Ref.gen(:full_reference => "doesnt matter", :published => 1, :visibility => Visibility.invisible)
    dor = Factory(:data_objects_ref, :data_object => d_o, :ref => ref)
    Ref.literature_references_for?(tc.id).should_not be_true
    Ref.find_refs_for(tc.id).size.should == 0
  end
  
  it "should not have a literature review when there are no data objects" do
    tc = Factory(:taxon_concept)
    Ref.literature_references_for?(tc.id).should_not be_true
    Ref.find_refs_for(tc.id).size.should == 0
  end
  
  it "should have literature reviews when taxa have references" do
    Ref.literature_references_for?(@tc_taxa_refs.id).should be_true
    Ref.find_refs_for(@tc_taxa_refs.id).size.should == 6
  end
  
  it "should not have a literature review" do
    tc = Factory(:taxon_concept)
    Ref.literature_references_for?(tc.id).should_not be_true
    Ref.find_refs_for(tc.id).size.should == 0
  end
end
