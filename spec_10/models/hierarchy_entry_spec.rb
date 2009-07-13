require File.dirname(__FILE__) + '/../spec_helper'
require 'eol_data'

def mock_common_name(tc_id, lang, result)
  TaxonConceptName.should_receive(:find_by_taxon_concept_id_and_language_id_and_vern_and_preferred).with(
                                                                                                  tc_id, lang.id, 1, 1).and_return(result)
end

# This is a private method, but I want to test it. No nyah.
describe HierarchyEntry, '#xml_for_group' do
  before(:each) do
    @he = HierarchyEntry.new
    @entry_1 = mock_model(HierarchyEntry, :node_xml => 'first')
    @entry_2 = mock_model(HierarchyEntry, :node_xml => 'second')
    @entry_3 = mock_model(HierarchyEntry, :node_xml => 'third')
    @group = [@entry_1, @entry_2, @entry_3]
    @user  = mock_user
    @he.instance_eval { def public_xml_for_group(a,b,c); xml_for_group(a,b,c); end }
  end
  it 'should return empty string if passed an empty group' do
    @he.public_xml_for_group([], 'whatever', @user).should == ''
  end
  it 'should wrap group in tag of second arg' do
    @he.public_xml_for_group(@group, 'this_tag', @user).should match /^\s*<this_tag>.*<\/this_tag>\s*$/m
  end
  it 'should call node_xml on every member of the group' do
    @entry_1.should_receive(:node_xml).and_return('first')
    @entry_2.should_receive(:node_xml).and_return('second')
    @entry_3.should_receive(:node_xml).and_return('third')
    @he.public_xml_for_group(@group, 'whatever', @user).should match /first\s*second\s*third/m
  end
  it 'should use current user options' do
    @entry_1.should_receive(:node_xml).with(@user).and_return('whatever')
    @he.public_xml_for_group([@entry_1], 'whatever', @user)
  end
end

describe HierarchyEntry, '#classification_attribution' do
  before(:each) do
    @hierarchy_label = 'Something really important that must be displayed'
    @he = HierarchyEntry.new
    @agent_h = mock_model(Agent)
    @agent_h.stub!(:display_name=).and_return(true)
    @agent_h.stub!(:full_name=).and_return(true)
    @agent1 = mock_model(Agent)
    @agent2 = mock_model(Agent)
    @he.stub!(:agents).and_return([@agent1, @agent2])
    @hierarchy = mock_model(Hierarchy)
    @hierarchy.stub!(:label).and_return(@hierarchy_label)
    @hierarchy.stub!(:agent).and_return(@agent_h)
    @he.stub!(:hierarchy).and_return(@hierarchy)
  end
  it 'should start with the agent for the hierarchy' do
    @hierarchy.should_receive(:agent).and_return(@agent_h)
    @he.classification_attribution.first.should == @agent_h
  end
  it 'should set the display_name and ful_name of the first agent to the hierarchy label' do
    @agent_h.should_receive(:display_name=).with(@hierarchy_label).and_return(true)
    @agent_h.should_receive(:full_name=).with(@hierarchy_label).and_return(true)
    @he.classification_attribution
  end
  it 'should add the hierarchy_entry\'s agents to the list' do
    @he.should_receive(:agents).and_return([@agent1, @agent2])
    @he.classification_attribution[1..-1].should == [@agent1, @agent2]
  end
end

describe HierarchyEntry, '#classification' do

  # Yeeesh.  ...Still, this is faster than fixtures:
  before(:each) do
    @ancestor_xml = '<tag>ancestor</tag>'
    @current_xml  = '<tag>current</tag>'
    @child_xml    = '<tag>child</tag>'
    @sibling_xml  = '<tag>sibling</tag>'
    @kingdom_xml  = '<tag>kingdom</tag>'
    @col_xml      = '<tag>CoL</tag>'
    @agent_xml    = '<tag>agent</tag>'
    @child_name   = 'Childus nameicus'
    @sibling_name = 'Siblingus nameicus'
    @another_sibling_name = 'Siblingus secundus'
    @hierarchy_label = 'Catalogue of Life, etc, etc'
    @he = HierarchyEntry.new
    @he.stub!(:node_xml).and_return(@current_xml)
    @agent = mock_model(Agent)
    @agent.stub!(:node_xml).and_return(@col_xml)
    @agent.stub!(:full_name=).and_return(true)
    @agent.stub!(:display_name=).and_return(true)
    @hierarchy = mock_model(Hierarchy)
    @hierarchy.stub!(:agent).and_return(@agent)
    @hierarchy.stub!(:label).and_return(@hierarchy_label)
    @he.stub!(:hierarchy).and_return(@hierarchy)
    @he.stub!(:hierarchy_id).and_return(@hierarchy.id)
    @user = mock_user
    User.stub!(:create_new).and_return(@user)
    @ancestor = mock_model(HierarchyEntry)
    @ancestor.stub!(:node_xml).and_return(@ancestor_xml)
    @he.stub!(:ancestors).and_return([@ancestor, @he])
    @he.stub!(:parent_id).and_return(@ancestor.id)
    @child = mock_model(HierarchyEntry)
    @child.stub!(:node_xml).and_return(@ancestor_xml)
    @child.stub!(:name).and_return(@child_name)
    @he.stub!(:children).and_return([@child])
    @sibling = mock_model(HierarchyEntry)
    @sibling.stub!(:name).and_return(@sibling_name)
    @another_sibling = mock_model(HierarchyEntry)
    @another_sibling.stub!(:name).and_return(@another_sibling_name)
    HierarchyEntry.stub!(:find_all_by_parent_id_and_hierarchy_id).and_return([@sibling, @another_sibling])
    @he.stub!(:xml_for_group).and_return(@child_xml)
    @he.stub!(:xml_for_group).with([@sibling, @another_sibling], 'siblings', @user).and_return(@sibling_xml)
    @kingdom = mock_model(HierarchyEntry)
    @he.stub!(:xml_for_group).with([@kingdom], 'kingdoms', @user).and_return(@kingdom_xml)
    @hierarchy.stub!(:kingdoms).and_return([@kingdom])
    @classification = mock_model(Agent)
    @classification.stub!(:node_xml).and_return(@agent_xml)
    @taxon = mock_model(TaxonConcept)
    @taxon.stub!(:classification_attribution).and_return([@classification])
    @he.stub!(:taxon_concept).and_return(@taxon)
    Hierarchy.stub!(:default).and_return(@hierarchy)
  end

  it 'should use options for user if passed in' do
    # NOTE: These two only happen if we have more than one child/sibling (so we have two):
    @user.should_receive(:expertise).at_least(1).times.and_return(:middle)
    @user.should_receive(:language).at_least(1).times.and_return(Language.english)
    @ancestor.should_receive(:node_xml).with(@user).and_return(@ancestor_xml)
    @he.should_receive(:node_xml).with(@user).and_return(@current_xml)
    @hierarchy.should_receive(:kingdoms).with(@user).and_return([@kingdom])
    @he.classification(:current_user => @user).should_not be_nil
  end

  it 'should create new user (for options) by default' do
    User.should_receive(:create_new).and_return(@user)
    @he.classification
  end

  it 'should start with <results>' do
    @he.classification.should match /^<results>/
  end

  it 'should include <ancestry> (sans current node)' do
    @he.classification.should match /<ancestry>.*#{@ancestor_xml}.*<\/ancestry>/m
    @he.classification.should_not match /<ancestry>.*#{@current_xml}.*<\/ancestry>/m
  end

  it 'should include <current>' do
    @he.classification.should match /<current>.*#{@current_xml}.*<\/current>/m
  end

  it 'should use xml_for_group on children' do
    @he.should_receive(:xml_for_group).with([@child], 'children', @user).and_return('jumpin jack flash')
    @he.classification.should match /jumpin jack flash/
  end

  it 'should use xml_for_group on siblings' do
    @he.should_receive(:xml_for_group).with([@sibling, @another_sibling], 'siblings', @user).and_return('saint peter on a pogo stick')
    @he.classification.should match /saint peter on a pogo stick/
  end

  it 'should use xml_for_group on kingdoms' do
    @he.should_receive(:xml_for_group).with([@kingdom], 'kingdoms', @user).and_return('satan on a segway')
    @he.classification.should match /satan on a segway/
  end

  # These next test doesn't include the wrapper tag, because the tag would have been added by xml_for_group
  it 'should include <kingdoms>' do
    @he.classification.should match /#{@kingdom_xml}/
  end

  it 'should include <attribution>' do
    @he.classification.should match /<attribution>.*#{@col_xml}.*<\/attribution>/m
  end

  it 'should exclude current node from kingdoms, if applicable' do
    @hierarchy.should_receive(:kingdoms).with(@user).and_return([@kingdom, @he])
    @he.should_not_receive(:xml_for_group).with([@kingdom, @he], 'kingdoms', @user)
    @he.should_receive(:xml_for_group).with([@kingdom], 'kingdoms', @user).and_return('current entry not here')
    @he.classification#.should match /current entry not here/
  end

end

describe HierarchyEntry, '#node_xml' do
  before(:each) do
    @name        = 'named'
    @rank_level  = 'ranked'
    @validity    = 'I need your validation'
    @enableitude = 'Thundercats HO!'
    @he = HierarchyEntry.new
    @he.should_receive(:name).and_return(@name)
    rank = mock_model(Rank)
    rank.should_receive(:label).and_return(@rank_level)
    @he.should_receive(:rank).and_return(rank)
    @he.should_receive(:valid).and_return(@validity)
    @he.should_receive(:enable).and_return(@enableitude)
    @xml = @he.node_xml(mock_user)
  end
  it 'should include id as taxonID' do
    @xml.should match /<taxonID>#{@he.id}<\/taxonID>/
  end
  it 'should include name as nameString' do
    @xml.should match /<nameString>#{@name}<\/nameString>/
  end
  it 'should include titlized rank level as rankName' do
    @xml.should match /<rankName>#{@rank_level.titleize}<\/rankName>/
  end
  it 'should include validity as valid' do
    @xml.should match /<valid>#{@validity}<\/valid>/
  end
  it 'should include enable as enable' do
    @xml.should match /<enable>#{@enableitude}<\/enable>/
  end
end

describe HierarchyEntry, '(smart image functions)' do
  before(:each) do
    @he = HierarchyEntry.new
  end
  it 'should be nil when no images exist' do
    @he.should_receive(:images).exactly(3).times.and_return(nil)
    @he.smart_thumb.should == nil
    @he.smart_medium_thumb.should == nil
    @he.smart_image.should == nil
  end
  it 'should delegate to the first image if images exist' do
    first = mock_model(DataObject)
    first.should_receive(:smart_thumb).and_return(:thumby)
    first.should_receive(:smart_medium_thumb).and_return(:middle)
    first.should_receive(:smart_image).and_return(:imagine)
    @he.should_receive(:images).at_least(3).times.and_return([first, :bad, :nope, :horrible])
    @he.smart_thumb.should == :thumby
    @he.smart_medium_thumb.should == :middle
    @he.smart_image.should == :imagine
  end
end

describe HierarchyEntry, '#kingdom' do
  it 'should grab the first ancestor as the kingdom' do
    he = HierarchyEntry.new
    he.should_receive(:ancestors).and_return([:yes, :no, :bad, :wrong, :nope])
    he.kingdom.should == :yes
  end
end

describe HierarchyEntry, '#ancestors' do
  
  before(:each) do
    @default_hierarchy = mock_model(Hierarchy, :id => 1)
    @other_hierarchy = mock_model(Hierarchy, :id => 2)
    
    #create default and not default ancestry
    @default_ancestry = []
    @other_ancestry = []
    @other_ancestry2 = []
    8.times do
      @default_ancestry << HierarchyEntry.create(:depth => 5, :ancestry => '', :lft => 3, :rgt => 3, :rank_id => 123, :name_id => 1, :identifier => '', :parent_id => (@default_ancestry.last.id rescue 0), :taxon_concept => TaxonConcept.create(:supercedure_id => 4), :hierarchy => @default_hierarchy)
    end
    8.times do
      @other_ancestry << HierarchyEntry.create(:depth => 5, :ancestry => '', :lft => 3, :rgt => 3, :rank_id => 123, :name_id => 1, :identifier => '', :parent_id => (@other_ancestry.last.id rescue 0), :taxon_concept => (@default_ancestry[@other_ancestry.length + 5].taxon_concept rescue TaxonConcept.create(:supercedure_id => 1)), :hierarchy => @other_hierarchy)
    end
    8.times do
      @other_ancestry2 << HierarchyEntry.create(:depth => 5, :ancestry => '', :lft => 3, :rgt => 3, :rank_id => 123, :name_id => 1, :identifier => '', :parent_id => (@other_ancestry2.last.id rescue 0), :taxon_concept => TaxonConcept.create(:supercedure_id => 1), :hierarchy => @other_hierarchy)
    end

    Hierarchy.stub!(:default).and_return(@default_hierarchy)
    @ancestors = [mock_model(HierarchyEntry, :parent => nil)]
    4.times do
      @ancestors << mock_model(HierarchyEntry, :parent => @ancestors.last)
    end
    @he = HierarchyEntry.new
    @he.hierarchy_id = @default_hierarchy.id
    @he.parent = @ancestors.last
    @other_he = @other_ancestry.last
    @other_he2 = @other_ancestry2.last
  end
  it 'should only do the math once' do
    # 2 times because it needs to check that it's non-nil once.  To prove that it really only runs the method once, I'll call it
    # three times (because it I called it twice, this test could pass. ...well, we could get nit-pickier, but that's not worthwhile.
    @he.should_receive(:parent).exactly(2).times.and_return(@ancestors.last)
    list = @he.ancestors
    @he.ancestors.should == list
    @he.ancestors.should == list
  end
  it 'should include self as the last member' do
    @he.ancestors.last.id.should == @he.id
  end
  it 'should include all parents in the array if in the default Hierarchy' do
    @he.ancestors[0..-2].should == @ancestors
  end
  it 'should include default hierarchy connecting to his entry (last element) via taxon_concepts of other hierarchy ancestry' do
    @other_he.ancestors.should == @default_ancestry << @other_he
  end
  it 'should include no hierarchy, only self, if there is no connection to Default Hierarchy at all' do
    @other_he2.ancestors.should == [@other_he2]
  end

end

describe HierarchyEntry, '#enable' do
  before(:each) do
    @he = HierarchyEntry.new
    content = mock_model(HierarchiesContent)
    content.stub!(:text).and_return(0)
    content.stub!(:image).and_return(0)
    @he.hierarchies_content = content
  end
  it 'should be disabled if there is no hierarchies_content' do
    @he.should_receive(:hierarchies_content).and_return(nil)
    @he.enable.should_not be_true
  end
  it 'should be disabled if it is a non-leaf node that is invalid' do
    @he.should_receive(:is_leaf_node?).and_return(false)
    @he.should_receive(:valid).and_return(false)
    @he.enable.should_not be_true
  end
  it 'should be enabled if it is not a leaf node that is valid' do
    @he.should_receive(:is_leaf_node?).and_return(false)
    @he.should_receive(:valid).and_return(true)
    @he.enable.should be_true
  end
  it 'should be enabled if a leaf node has text' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.hierarchies_content.should_receive(:text).and_return(1)
    @he.enable.should be_true
  end
  it 'should be enabled if a leaf node has images' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.hierarchies_content.should_receive(:image).and_return(1)
    @he.enable#.should be_true
  end
  it 'should be disabled if a leaf node has neither images nor text' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.enable.should_not be_true
  end
end

describe HierarchyEntry, '#valid' do
  before(:each) do
    @he = HierarchyEntry.new
    content = mock_model(HierarchiesContent)
    content.stub!(:content_level).and_return(0)
    @he.hierarchies_content = content
  end
  it 'should be invalid if there is no hierarchies_content' do
    @he.should_receive(:hierarchies_content).and_return(nil)
    @he.valid.should_not be_true
  end
  it 'should be valid if the content level is greather than VALID_CONTENT_LEVEL' do
    @he.hierarchies_content.should_receive(:content_level).and_return($VALID_CONTENT_LEVEL + 1)
    @he.valid.should be_true
  end
  it 'should be valid if the content level is equal to VALID_CONTENT_LEVEL' do
    @he.hierarchies_content.should_receive(:content_level).and_return($VALID_CONTENT_LEVEL)
    @he.valid.should be_true
  end
  it 'should be INVALID if the content level is less than VALID_CONTENT_LEVEL' do
    @he.hierarchies_content.should_receive(:content_level).and_return($VALID_CONTENT_LEVEL - 1)
    @he.valid.should_not be_true
  end
end

describe HierarchyEntry, '#map' do
  it 'should call images_for_hierarchy_entry and cache the value' do
    he = HierarchyEntry.new
    DataObject.should_receive(:map_for_hierarchy_entry).exactly(1).times.and_return(:yep)
    he.map.should == (:yep)
    he.map.should == (:yep)
  end
end

describe HierarchyEntry, '#videos' do
  it 'should call images_for_hierarchy_entry and cache the value' do
    he = HierarchyEntry.new
    DataObject.should_receive(:videos_for_hierarchy_entry).exactly(1).times.and_return(:yep)
    he.videos.should == (:yep)
    he.videos.should == (:yep)
  end
end

describe HierarchyEntry, '#images' do
  it 'should call images_for_hierarchy_entry and cache the value' do
    he = HierarchyEntry.new
    DataObject.should_receive(:images_for_hierarchy_entry).exactly(1).times.and_return(:yep)
    he.images.should == (:yep)
    he.images.should == (:yep)
  end
end

describe HierarchyEntry, '(ranks and nodes)' do
  it 'should call a species 335' do
    HierarchyEntry.species_rank.should == 335
  end
  it 'should call infraspecies_rank 175' do
    HierarchyEntry.infraspecies_rank.should == 175
  end
  it 'should use species_rank and infraspecies_rank to build leaf_node_ranks' do
    HierarchyEntry.should_receive(:species_rank).and_return(:one)
    HierarchyEntry.should_receive(:infraspecies_rank).and_return(:two)
    HierarchyEntry.leaf_node_ranks.should == [:one, :two]
  end
  it 'should look for ranks in leaf_node_ranks to decide is_leaf_node?' do
    ranks = [1,2,3]
    HierarchyEntry.should_receive(:leaf_node_ranks).at_least(ranks.length + 1).times.and_return(ranks)
    he = HierarchyEntry.new
    ranks.each do |rank| 
      he.rank_id = rank
      he.is_leaf_node?.should be_true
    end
    he.rank_id = 5
    he.is_leaf_node?.should_not be_true
  end
end

describe HierarchyEntry, '#with_parents' do
  it 'should delegate to the Class method off of an instance' do
    he = HierarchyEntry.new
    HierarchyEntry.should_receive(:with_parents).with(he).and_return(:blah)
    he.with_parents.should == :blah
  end
  it 'should also call hierarchy_entries_with_parents' do
    he = HierarchyEntry.new
    HierarchyEntry.should_receive(:with_parents).with(he).and_return(:blah)
    he.hierarchy_entries_with_parents.should == :blah
  end
  it 'should call find_all_by_taxon_concept_id if TaxonConcept' do
    HierarchyEntry.should_receive(:find_all_by_taxon_concept_id).and_return([])
    HierarchyEntry.with_parents(TaxonConcept.new)
  end
  it 'should add ancestors to self if passed a HE' do
    he = HierarchyEntry.new
    he.should_receive(:ancestors).and_return([:foo])
    HierarchyEntry.with_parents(he).should == [he, :foo]
  end
  it 'should raise errors when given funky arguments' do
    lambda { HierarchyEntry.with_parents(ContentPartner.new)}.should raise_error
  end
end

describe HierarchyEntry, '#iucn' do
  it 'should create a new data object(with IUCN stuff) if it cant find anything' do
  end
end

describe HierarchyEntry, '#iucn' do
  it 'should create a new data object(with IUCN stuff) if it cant find anything' do
    he = HierarchyEntry.new
    DataObject.should_receive(:find_by_sql).and_return([])
    DataObject.should_receive(:new).with(:source_url => 'http://www.iucnredlist.org/', :description => 'NOT EVALUATED').and_return(:foo)
    he.iucn.should == :foo
  end
  it 'should return results from the search when non-blank' do
    he = HierarchyEntry.new
    DataObject.should_receive(:find_by_sql).and_return([:something])
    he.iucn.should == [:something]
  end
end

describe HierarchyEntry, '#content_level' do
  before(:each) do 
    @he = HierarchyEntry.new
    @he.stub!(:is_leaf_node?).and_return(true)
    content = mock_model(HierarchiesContent)
    content.stub!(:content_level).and_return(4)
    content.stub!(:text).and_return(1)
    @he.hierarchies_content = content
  end
  it 'should delegate CL to content if NOT a leaf node and it has a content entry' do
    @he.should_receive(:is_leaf_node?).and_return(false)
    @he.hierarchies_content.should_receive(:content_level).at_least(1).times.and_return(:foo)
    @he.content_level.should == :foo
  end
  it 'should be 1 if content is CL0 and its NOT a leaf node' do
    @he.should_receive(:is_leaf_node?).and_return(false)
    @he.hierarchies_content.should_receive(:content_level).and_return(0)
    @he.content_level.should == 1
  end
  it 'should be 4 if content is CL4 and its a leaf node' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.hierarchies_content.should_receive(:content_level).and_return(4)
    @he.content_level.should == 4
  end
  it 'should be 0 if its NOT a leaf node and it has no content entry' do
    @he.should_receive(:is_leaf_node?).and_return(false)
    @he.hierarchies_content = nil
    @he.content_level.should == 0
  end
  it 'should be 1 if its a leaf node and it has no text' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.hierarchies_content.should_receive(:content_level).and_return(0) # Doesn't matter, just not 4
    @he.hierarchies_content.should_receive(:text).and_return(0)
    @he.content_level.should == 1
  end
  it 'should be 3 if its a leaf node and it has text' do
    @he.should_receive(:is_leaf_node?).and_return(true)
    @he.hierarchies_content.should_receive(:content_level).and_return(0) # Doesn't matter, just not 4
    @he.hierarchies_content.should_receive(:text).and_return(1)
    @he.content_level.should == 3
  end
end

describe HierarchyEntry, 'empty name' do
  it 'should return "?" if no name id is associated with it' do
    he = HierarchyEntry.new
    he.name.should == '?'
    he.raw_name.should == '?'
  end
end

describe HierarchyEntry, 'names' do

  before(:each) do
    @he = HierarchyEntry.new
    @mock_name = mock_model(Name)
    @he[:name_id] = @mock_name.id
    @he[:rank_id] = @mock_rank_id = 97531
    @mock_taxon_concept = mock_model(TaxonConcept)
    @he.taxon_concept = @mock_taxon_concept
    Name.stub!(:find).with(@mock_name.id).and_return(@mock_name)
    @mock_language = mock_model(Language)
  end

  it 'should use name() to capitalize raw_name' do
    @he.should_receive(:raw_name).and_return('some string')
    @he.name.should == 'Some string'
  end

  it 'should fake italics (incuding capitalization) if the italics is actually missing' do
    @mock_name.should_receive(:italicized).and_return("")
    @mock_name.should_receive(:string).and_return("here we are")
    @he.raw_name(:expert, @mock_language).should == "<i>Here we are</i>"
  end

  it 'should produce italicized_canonical' do
    @mock_name.should_receive(:italicized_canonical).and_return(:success)
    @he.raw_name(:italicized_canonical, @mock_language).should == :success
  end

  it 'should produce canonical' do
    @mock_name.should_receive(:canonical).and_return(:success)
    @he.raw_name(:canonical, @mock_language).should == :success
  end

  it 'should produce natural_form from name.string' do
    @mock_name.should_receive(:string).and_return(:success)
    @he.raw_name(:natural_form, @mock_language).should == :success
  end

  it 'should produce name.italicized if expert' do
    @mock_name.should_receive(:italicized).and_return(:success)
    @he.raw_name(:expert, @mock_language).should == :success
  end

  it 'should produce name_italicized (again) if expert in classification context and IT IS a leaf node' do
    HierarchyEntry.should_receive(:leaf_node_ranks).and_return([1, @mock_rank_id, 2, 3])
    @mock_name.should_receive(:italicized).and_return(:success)
    @he.raw_name(:expert, @mock_language, :classification).should == :success
  end

  it 'should produce name.string (natural_form) if expert in classification context and not a leaf node' do
    HierarchyEntry.should_receive(:leaf_node_ranks).and_return([1, 2, 3])
    @mock_name.should_receive(:string).and_return(:success)
    @he.raw_name(:expert, @mock_language, :classification).should == :success
  end

  it 'should default to english if no language provided' do
    test_lang = mock_model(Language)
    Language.should_receive(:english).at_least(1).times.and_return(test_lang)
    mock_common_name(@mock_taxon_concept.id, test_lang, nil)
    @mock_name.stub!(:italicized_canonical).and_return(:success) # We don't care about this, thus the stub
    @he.raw_name # don't care about the result, either.
  end

  it 'should return (common) name object if in object context' do
    common_tc_name = mock_model(TaxonConceptName)
    mock_common_name(@mock_taxon_concept.id, @mock_language, common_tc_name)
    @he.raw_name(nil, @mock_language, :object).should == common_tc_name
  end

  it 'should return common_name.raw_name.string if common name exists' do
    common_name = mock_model(Name)
    common_name.should_receive(:string).and_return(:success)
    common_tc_name = mock_model(TaxonConceptName)
    common_tc_name.should_receive(:name).and_return(common_name)
    mock_common_name(@mock_taxon_concept.id, @mock_language, common_tc_name)
    @he.raw_name(nil, @mock_language).should == :success
  end

  it 'should return italicized_canonical if common name doesnt exist' do
    mock_common_name(@mock_taxon_concept.id, @mock_language, nil)
    @mock_name.should_receive(:italicized_canonical).and_return(:success)
    @he.raw_name(nil, @mock_language).should == :success
  end


  it 'should return name.string (natural_form) if common name doesnt exist in classification context' do
    mock_common_name(@mock_taxon_concept.id, @mock_language, nil)
    @mock_name.should_receive(:string).and_return(:success)
    @he.raw_name(nil, @mock_language, :classification).should == :success
  end

end

describe HierarchyEntry, '#media' do

  before(:each) do
    @he = HierarchyEntry.new
    content = mock_model(HierarchiesContent)
    content.stub!(:image).and_return(0)
    content.stub!(:child_image).and_return(0)
    content.stub!(:flash).and_return(0)
    content.stub!(:youtube).and_return(0)
    content.stub!(:gbif_image).and_return(0)
    @he.hierarchies_content = content
  end

  it 'should have map when gbif_image is set' do
    @he.hierarchies_content.should_receive(:gbif_image).and_return(1)
    @he.media[:map].should be_true
  end

  it 'should have video when content has no flash, but does have youtube' do
    @he.hierarchies_content.should_receive(:flash).and_return(0)
    @he.hierarchies_content.should_receive(:youtube).and_return(1)
    @he.media[:video].should be_true
  end

  it 'should have video when flash is set' do
    @he.hierarchies_content.should_receive(:flash).and_return(1)
    @he.media[:video].should be_true
  end

  it 'should have images when content has no image, but child does' do
    @he.hierarchies_content.should_receive(:image).and_return(0)
    @he.hierarchies_content.should_receive(:child_image).and_return(1)
    @he.media[:images].should be_true
  end

  it 'should have images when content has an image' do
    @he.hierarchies_content.should_receive(:image).and_return(1)
    @he.media[:images].should be_true
  end

end

describe HierarchyEntry, '#toc' do
  it 'should call TocItem.toc_for' do
    TocItem.should_receive(:toc_for).and_return(:hi)
    he = HierarchyEntry.new
    he.toc.should == :hi
  end
end

describe HierarchyEntry do

  fixtures :hierarchy_entries, :hierarchies_content, :canonical_forms, :names

  before(:each) do
    @roenbergensis = HierarchyEntry.find(hierarchy_entries(:roenbergensis).id)
    @named         = HierarchyEntry.find(hierarchy_entries(:search).id)
  end

  it 'should have one hierarchies content' do
    @roenbergensis.hierarchies_content.should be_an_instance_of(HierarchiesContent) 
  end

end

describe HierarchyEntry, 'nested set' do

  # make a method so i can understand wtf is going on
  
  class HierarchyEntry
    def to_s
      "HE[ name:#{name} lft:#{lft} rgt:#{rgt} depth:#{depth} ]"
    end
  end

  class Object
    # hacky method that I'm using to make some assertions ... should be a custom matcher
    def children_shouldnt_have_an_id_outside_the_range_of min, max
      if respond_to?:children
        self.children.each do |child|
          ## puts "entry: #{ child } is <= min: #{ min }" if child.lft <= min
          child.lft.should > min

          ## puts "entry: #{ child } is >= max: #{ max }" if child.lft >= max
          child.lft.should < max

          child.children_shouldnt_have_an_id_outside_the_range_of child.lft, child.rgt
        end
      else
        puts "i don't respond_to?:children!  #{ self }"
      end
    end
  end

  include EOL::Data
  include EOL::Print

  it 'fixtures should already be a nested set' do
    h_s = Hierarchy.find(:all)
    
    Hierarchy.last.hierarchy_entries.select {|he| he.parent_id == 0 }.each do |entry|
      entry.children_shouldnt_have_an_id_outside_the_range_of(entry.lft, entry.rgt)
    end
  end

  # original example - HierarchyEntry fixtures were failing this spec, make_nested_set via EOL::Data fixed them
  #
  # if this passed but 'fixtures should already be a nested set' fails, then the hierarchy_entries.yml fixture
  # needs to be re-generated: 
  #   $ rake eol:data:generate_hierarchy_entries_yml  # Creates hierachy_entries.yml for testing purposes.
  it 'should form a valid nested set structure' do
    h_s = Hierarchy.find(:all)
    h_s.each do |h|
      make_nested_set(h)
    end
    
    Hierarchy.last.hierarchy_entries.select {|he| he.parent_id == 0 }.each do |entry|
      entry.children_shouldnt_have_an_id_outside_the_range_of(entry.lft, entry.rgt)
    end
  end

end

describe HierarchyEntry, 'curation' do

  fixtures :hierarchy_entries, :users

  before(:each) do
    @jrice = User.find(users(:jrice).id)   # Approved for cafeteria
    @jrice2 = User.find(users(:jrice2).id) # Not approved (wants cafeteria)
    @admin = User.find(users(:admin).id)   # Approved for chromista
  end
  
  it 'should only find users with approval and curator_hierarchy_entry_id matching parents' do
    cafe = hierarchy_entries(:h2_cafeteria)
    approved = cafe.approved_curators
    approved.size.should == 2
    approved.should include(@admin)
    approved.should include(@jrice)
    approved.should_not include(@jrice2)
  end
  
end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: hierarchy_entries
#
#  id               :integer(4)      not null, primary key
#  hierarchy_id     :integer(2)      not null
#  name_id          :integer(4)      not null
#  parent_id        :integer(4)      not null
#  rank_id          :integer(2)      not null
#  remote_id        :string(255)     not null
#  taxon_concept_id :integer(4)      not null
#  ancestry         :string(500)     not null
#  depth            :integer(1)      not null
#  identifier       :string(20)      not null
#  lft              :integer(4)      not null
#  rgt              :integer(4)      not null
# == Schema Info
# Schema version: 20081020144900
#
# Table name: hierarchy_entries
#
#  id               :integer(4)      not null, primary key
#  hierarchy_id     :integer(2)      not null
#  name_id          :integer(4)      not null
#  parent_id        :integer(4)      not null
#  rank_id          :integer(2)      not null
#  remote_id        :string(255)     not null
#  taxon_concept_id :integer(4)      not null
#  ancestry         :string(500)     not null
#  depth            :integer(1)      not null
#  identifier       :string(20)      not null
#  lft              :integer(4)      not null
#  rgt              :integer(4)      not null

