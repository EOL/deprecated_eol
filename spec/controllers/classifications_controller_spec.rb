require File.dirname(__FILE__) + '/../spec_helper'

describe ClassificationsController do

  before(:all) do
   # load_scenario_with_caching :foundation
    # truncate_all_tables
    Language.create_english    
    Visibility.create_enumerated
    CuratorLevel.create_enumerated
    Vetted.create_enumerated
    DataType.create_enumerated
    SpecialCollection.create_enumerated
    ChangeableObjectType.create_enumerated
    Activity.create_enumerated
    @taxon_concept = TaxonConcept.gen # Doesn't need to *do* anything special.
    @hierarchy_entry = HierarchyEntry.gen # Again, can be "dumb".
    @curator = User.gen(:credentials => 'awesome', :curator_scope => 'life')
    @curator.grant_curator(:full)    
  end

  before(:each) do
    TaxonConceptPreferredEntry.delete_all
    CuratedTaxonConceptPreferredEntry.delete_all("taxon_concept_id = #{@taxon_concept.id}")
  end

  # TODO - this is written as a feature spec.

  it 'should work, dammit' do
    session[:user_id] = @curator.id    
    post :create, :taxon_concept_id => @taxon_concept.id, :hierarchy_entry_id => @hierarchy_entry.id
    # 'and only have one CTCPE'
    if CuratedTaxonConceptPreferredEntry.count("taxon_concept_id = #{@taxon_concept.id}") > 1
      puts "...There are an extra two CuratedTaxonConceptPreferredEntrys for TC #{@taxon_concept.id}, aren't there?"
      puts "...Please investigate as to why, since we should be deleting them before each spec."
    end
    CuratedTaxonConceptPreferredEntry.count("taxon_concept_id = #{@taxon_concept.id}").should == 1
    ctcpe = CuratedTaxonConceptPreferredEntry.last
    # 'and the CTCPE should point to the right things'
    ctcpe.taxon_concept_id.should == @taxon_concept.id
    ctcpe.hierarchy_entry_id.should == @hierarchy_entry.id
    ctcpe.user_id.should == @curator.id
    # 'and should log the right thing'
    cal = CuratorActivityLog.last    
    cal.user.should == @curator
    cal.changeable_object_type.should == ChangeableObjectType.curated_taxon_concept_preferred_entry
    cal.target_id.should == ctcpe.id
    cal.hierarchy_entry.should == @hierarchy_entry
    cal.taxon_concept.should == @taxon_concept
    cal.activity.should == Activity.preferred_classification
  end

  it 'should update an existing tcpe' do
    @old_he = HierarchyEntry.gen
    TaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id, :hierarchy_entry_id => @old_he.id)
    session[:user_id] = @curator.id
    post :create, :taxon_concept_id => @taxon_concept.id, :hierarchy_entry_id => @hierarchy_entry.id
    # NOTE - this next bit is... weird.  I tried doing a #count, but for some reason, it was *finding* the old entry
    # with that method.  :\  So, anyway:
    TaxonConceptPreferredEntry.find_all_by_taxon_concept_id(@taxon_concept.id).each do |tcpe|
      tcpe.hierarchy_entry_id.should_not == @old_he.id
    end
  end

  it 'should do nothing if you are NOT a curator' do
    session[:user_id] = User.gen.id
    post :create, :taxon_concept_id => @taxon_concept.id, :hierarchy_entry_id => @hierarchy_entry.id
    CuratedTaxonConceptPreferredEntry.count("taxon_concept_id = #{@taxon_concept.id}").should == 0
  end

end
