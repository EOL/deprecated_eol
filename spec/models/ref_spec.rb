require File.dirname(__FILE__) + '/../spec_helper'

describe Ref do
  
  before(:all) do
    EolScenario.load :foundation
  end

  describe "Literature reviews" do
    
    before(:all) do
      Factory(:toc_item, :label => "Literature Review")
    end
    
    before(:each) do
      @tc = Factory(:taxon_concept)
    end
    
    after(:all) do
      Rails.cache.clear
    end
    
    describe "when a Data object taxon exists" do
      before(:each) do
        @he = []
        4.times do
          # he = Factory(:hierarchy_entry, :taxon_concept => @tc)
          @he << Factory(:hierarchy_entry, :taxon_concept => @tc)
        end
        @he.each do |he|
          2.times do
            d_o = Factory(:data_object)
            dohe = Factory(:data_objects_hierarchy_entry, :hierarchy_entry => he, :data_object => d_o)
            ref = Factory(:ref)
            dor = Factory(:data_objects_ref, :data_object => d_o, :ref => ref)
          end
        end
      end

      it "should have literature reviews" do
        Ref.literature_references_for?(@tc.id).should be_true
        Ref.find_refs_for(@tc.id).size.should == 8
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

    end
    
    describe "when a Data object taxon doesn't exist" do
      it "should not have a literature review" do
        Ref.literature_references_for?(@tc.id).should_not be_true
        Ref.find_refs_for(@tc.id).size.should == 0
      end
    end
    
    describe "when a Taxon reference exists" do
      before(:each) do
        @he = []
        4.times do 
          @he << Factory(:hierarchy_entry, :taxon_concept => @tc)
        end
        @he.each do |he|
          2.times do
            ref = Factory(:ref)
            Factory(:hierarchy_entries_ref, :ref => ref, :hierarchy_entry => he)
          end
        end
      end
      it "should have literature reviews" do
        Ref.literature_references_for?(@tc.id).should be_true
        Ref.find_refs_for(@tc.id).size.should == 8
      end
    end

    describe "when no Taxon reference exists" do
      it "should not have a literature review" do
        Ref.literature_references_for?(@tc.id).should_not be_true
        Ref.find_refs_for(@tc.id).size.should == 0
      end
    end

  end
end
