require File.dirname(__FILE__) + '/../spec_helper'

describe 'build_taxon_concept (spec helper method)' do

  before(:all) do
    Scenario.load :foundation
    @event           = HarvestEvent.gen
    @scientific_name = 'Something cool'
    @hierarchy       = Hierarchy.gen
    @taxon_concept   = build_taxon_concept
    @taxon_concept_with_args = build_taxon_concept(
      :hierarchy       => @hierarchy,
      :event           => @event,
      :scientific_name => @scientific_name
    )
    @taxon_concept_naked = build_taxon_concept(
      :images => [], :toc => [], :flash => [], :youtube => [], :comments => [], :bhl => []
    )
    @taxon_concept_naked.current_user = User.gen(:vetted => true) # Otherwise things aren't empty
  end

  it 'should be able to make a TC with no common names and an empty TOC' do
    @taxon_concept_naked.table_of_contents.blank?.should be_true
  end

  it 'should not have a common name by defaut' do
    @taxon_concept.common_name.blank?.should be_true
  end

  it 'should put all new hierarchy_entries under the default hierarchy if none supplied'  do
    @taxon_concept.hierarchy_entries.each do |he|
      he.hierarchy.should == Hierarchy.default
    end
  end

  it 'should put all new hierarchy_entries under the hierarchy supplied' do
    @taxon_concept_with_args.hierarchy_entries.each do |he|
      he.hierarchy.should == @hierarchy
    end
  end

  it 'should use default HarvestEvent if no alternative provided' do
    @taxon_concept.images.each do |img|
      img.harvest_events.should only_include(default_harvest_event)
    end
  end

  it 'should use the supplied HarvestEvent to create all data objects' do
    @taxon_concept_with_args.images.each do |img|
      img.harvest_events.should only_include(@event)
    end
  end

  it 'should create a scientific name' do
    @taxon_concept_naked.scientific_name.should_not be_nil
    @taxon_concept_naked.scientific_name.should_not == ''
  end

  it 'should create a scientific name when specified' do
    @taxon_concept_with_args.scientific_name.should == @scientific_name
  end

end
