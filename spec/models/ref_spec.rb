require File.dirname(__FILE__) + '/../spec_helper'

describe Ref do

  before(:all) do
    load_foundation_cache
    TocItem.gen_if_not_exists(:label => "Literature Review") # Where the refs show up.

    @tc_object_refs = FactoryGirl.create(:taxon_concept)
    @he_object_refs = []
    4.times do
      @he_object_refs << FactoryGirl.create(:hierarchy_entry, :taxon_concept => @tc_object_refs)
    end
    @he_object_refs.each do |he|
      2.times do
        d_o = FactoryGirl.create(:data_object)
        dohe = FactoryGirl.create(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
        dohe = FactoryGirl.create(:data_objects_taxon_concept, :taxon_concept => he.taxon_concept, :data_object => d_o)
        ref = FactoryGirl.create(:ref)
        dor = FactoryGirl.create(:data_objects_ref, :data_object => d_o, :ref => ref)
      end
    end

    @tc_taxa_refs = FactoryGirl.create(:taxon_concept)
    @he_taxa_refs = []
    3.times do
      @he_taxa_refs << FactoryGirl.create(:hierarchy_entry, :taxon_concept => @tc_taxa_refs)
    end
    @he_taxa_refs.each do |he|
      2.times do
        ref = FactoryGirl.create(:ref)
        FactoryGirl.create(:hierarchy_entries_ref, :ref => ref, :hierarchy_entry => he)
      end
    end
  end

  it "should have literature reviews when objects have references" do
    Ref.literature_references_for?(@tc_object_refs.id).should be_true
    Ref.find_refs_for(@tc_object_refs.id).size.should == 8
    @tc_object_refs.has_literature_references?.should be_true
  end

  it "should have literature references when the reference is visible and published" do
    tc = FactoryGirl.create(:taxon_concept)
    he = FactoryGirl.create(:hierarchy_entry, :taxon_concept => tc)
    d_o = FactoryGirl.create(:data_object)
    dohe = FactoryGirl.create(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
    dohe = FactoryGirl.create(:data_objects_taxon_concept, :taxon_concept => tc, :data_object => d_o)
    ref = Ref.gen(:full_reference => "doesnt matter", :published => 1, :visibility => Visibility.visible)
    dor = FactoryGirl.create(:data_objects_ref, :data_object => d_o, :ref => ref)
    Ref.literature_references_for?(tc.id).should be_true
    tc.has_literature_references?.should be_true
    Ref.find_refs_for(tc.id).size.should == 1
  end

  it "should not have literature references when the reference is unpublished"  do
      tc = FactoryGirl.create(:taxon_concept)
      he = FactoryGirl.create(:hierarchy_entry, :taxon_concept => tc)
      d_o = FactoryGirl.create(:data_object)
      dohe = FactoryGirl.create(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
      ref = Ref.gen(:full_reference => "doesnt matter", :published => 0, :visibility => Visibility.visible)
      dor = FactoryGirl.create(:data_objects_ref, :data_object => d_o, :ref => ref)
      Ref.literature_references_for?(tc.id).should_not be_true
      tc.has_literature_references?.should_not be_true
      Ref.find_refs_for(tc.id).size.should == 0
    end

  it "should not have literature references when the reference is invisible" do
      tc = FactoryGirl.create(:taxon_concept)
      he = FactoryGirl.create(:hierarchy_entry, :taxon_concept => tc)
      d_o = FactoryGirl.create(:data_object)
      dohe = FactoryGirl.create(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
      ref = Ref.gen(:full_reference => "doesnt matter", :published => 1, :visibility => Visibility.invisible)
      dor = FactoryGirl.create(:data_objects_ref, :data_object => d_o, :ref => ref)
      Ref.literature_references_for?(tc.id).should_not be_true
      tc.has_literature_references?.should_not be_true
      Ref.find_refs_for(tc.id).size.should == 0
    end

  it "should not have a literature review when there are no data objects"  do
      tc = FactoryGirl.create(:taxon_concept)
      Ref.literature_references_for?(tc.id).should_not be_true
      tc.has_literature_references?.should_not be_true
      Ref.find_refs_for(tc.id).size.should == 0
    end

  it "should have literature reviews when taxa have references" do
    Ref.literature_references_for?(@tc_taxa_refs.id).should be_true
    @tc_taxa_refs.has_literature_references?.should be_true
    Ref.find_refs_for(@tc_taxa_refs.id).size.should == 6
  end

  it "should not have a literature review" do
      tc = FactoryGirl.create(:taxon_concept)
      Ref.literature_references_for?(tc.id).should_not be_true
      tc.has_literature_references?.should_not be_true
      Ref.find_refs_for(tc.id).size.should == 0
    end
end
