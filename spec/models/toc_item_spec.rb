require File.dirname(__FILE__) + '/../spec_helper'

describe TocItem do

  fixtures :toc_items

  before(:each) do
    @toc_item = toc_items(:table_of_contents_1)
  end

  it 'should have a writable has_content attribute' do
    @toc_item.has_content?.should be_nil
    @toc_item.has_content = true
    @toc_item.has_content?.should == true
  end

end

describe TocItem, 'no fixtures' do

  it 'should identify whether it is a child node' do
    @toc_item = TocItem.new(:parent_id => nil)
    @toc_item.is_child?.should_not be_true
    @toc_item.parent_id = 0
    @toc_item.is_child?.should_not be_true
    @toc_item.parent_id = 1
    @toc_item.is_child?.should be_true
  end

end

describe TocItem, '#toc_for (with fixtures)' do
  fixtures :toc_items, :data_objects_table_of_contents, :data_objects, :agents_data_objects,
               :data_objects_taxa, :taxa, :taxon_concept_names , :taxon_concepts

  before(:each) do
    @toc = []
    #(1..17).each { |num| @toc << data_objects_table_of_contents("cafeteria_dotoc_#{num}".to_sym).toc_id }
    
    @toc << toc_items(:table_of_contents_1).id
    @toc << toc_items(:table_of_contents_3).id
    @toc << toc_items(:table_of_contents_4).id
    @toc << toc_items(:table_of_contents_5).id
    @toc << toc_items(:table_of_contents_7).id
    @toc << toc_items(:table_of_contents_17).id
    @toc << toc_items(:table_of_contents_18).id
    @toc << toc_items(:table_of_contents_19).id
    @toc << toc_items(:table_of_contents_20).id
    @toc << toc_items(:table_of_contents_23).id
    @toc << toc_items(:table_of_contents_26).id
    @toc << toc_items(:table_of_contents_27).id
    @toc << toc_items(:table_of_contents_28).id
    @toc << toc_items(:table_of_contents_29).id
    @toc << toc_items(:table_of_contents_30).id
    @toc << toc_items(:table_of_contents_206).id
    @toc << toc_items(:table_of_contents_222).id
    @toc << toc_items(:table_of_contents_223).id
    @toc << toc_items(:table_of_contents_225).id
    @toc << toc_items(:table_of_contents_226).id
    
    @preview_toc = (@toc + [toc_items(:table_of_contents_2).id]).uniq.sort
    @toc = @toc.uniq.sort
  end

  it 'should create a TOC for a given taxon_concept' do
    pp TocItem.toc_for(taxon_concepts(:cafeteria).id).collect {|toci| toci.id }.sort
    TocItem.toc_for(taxon_concepts(:cafeteria).id).collect {|toci| toci.id }.sort.should == @toc
  end

  it 'should create a TOC including preview items for a given taxon_concept and agent' do
    TocItem.toc_for(taxon_concepts(:cafeteria).id, :agent => agents_data_objects(:text_preview).agent).
      collect {|toci| toci.id }.sort.should == @preview_toc
  end

end

def mock_toc_item(order)
  mock = mock_model(TocItem)
  mock.stub!(:parent_id).and_return(0)
  mock.stub!(:is_child?).and_return(false)
  mock.stub!(:view_order).and_return(order)
  mock.stub!(:has_content).and_return(true)
  mock.stub!(:vetted_id).and_return(Vetted.trusted.id)
  mock.stub!('has_content=').with(true).and_return(nil)
  return mock
end

describe TocItem, '#toc_for' do
  
  before(:each) do
    @taxon           = mock_model(TaxonConcept)
    @mock_toc        = mock_toc_item(2)
    @mock_search_web = mock_toc_item(3)
    TocItem.stub!(:find_by_sql).and_return([@mock_toc])
    Mapping.stub!(:count_by_sql).and_return(0)
    PageName.stub!(:count_by_sql).and_return(0)
    TaxonConcept.stub!(:count_by_sql).and_return(0)
    TaxonConcept.stub!(:find).with(@taxon.id).and_return(@taxon)
    TocItem.stub!(:search_the_web).and_return(@mock_search_web)
  end

  it 'should add empty parents to a toc' do
    mock_parent = mock_toc_item(1)
    TocItem.should_receive(:find).with(mock_parent.id).and_return(mock_parent)
    @mock_toc.should_receive(:is_child?).at_least(1).times.and_return(true)
    @mock_toc.should_receive(:parent_id).at_least(1).times.and_return(mock_parent.id)
    TocItem.toc_for(@taxon.id).should == [mock_parent, @mock_toc, @mock_search_web]
  end

  it 'should sort the TOC correctly' do
    # I'll reverse the order, just beacuse other tests are ensuring the same thing, elsewhere.
    @mock_search_web.should_receive(:view_order).at_least(1).times.and_return(1)
    @mock_toc.should_receive(:view_order).at_least(1).times.and_return(2)
    TocItem.toc_for(@taxon.id).should == [@mock_search_web, @mock_toc]
  end

  it 'should add "search the web"' do
    TocItem.should_receive(:search_the_web).and_return(@mock_search_web)
    TocItem.toc_for(@taxon.id).should == [@mock_toc, @mock_search_web]
  end

  it 'should NOT add "search the web" when vetted-only' do
    TocItem.should_not_receive(:search_the_web)
    TocItem.toc_for(@taxon.id, :vetted_only => true).should == [@mock_toc]
  end

  it 'should add specialist project if there are any' do
    mock_special = mock_toc_item(1)
    Mapping.should_receive(:count_by_sql).and_return(1)
    TocItem.should_receive(:specialist_projects).and_return(mock_special)
    TocItem.toc_for(@taxon.id).should == [mock_special, @mock_toc, @mock_search_web]
  end

  it 'should NOT add specialist projects if there are none' do
    Mapping.should_receive(:count_by_sql).and_return(0)
    TocItem.should_not_receive(:specialist_projects)
    TocItem.toc_for(@taxon.id).should == [@mock_toc, @mock_search_web]
  end

  it 'should add BHL library stuff if concepts link to page names' do
    bhl = mock_toc_item(1)
    PageName.should_receive(:count_by_sql).and_return(1)
    TocItem.should_receive(:bhl).and_return(bhl)
    TocItem.toc_for(@taxon.id).should == [bhl, @mock_toc, @mock_search_web]
  end

  it 'should NOT add BHL library stuff if concepts cannot link to page names' do
    PageName.should_receive(:count_by_sql).and_return(0)
    TocItem.should_not_receive(:bhl)
    TocItem.toc_for(@taxon.id).should == [@mock_toc, @mock_search_web]
  end

  it 'should add common names if it has any' do
    common_names = mock_toc_item(1)
    TaxonConcept.should_receive(:count_by_sql).and_return(1)
    TocItem.should_receive(:common_names).and_return(common_names)
    TocItem.toc_for(@taxon.id).should == [common_names, @mock_toc, @mock_search_web]
  end

  it 'should NOT add common names if there are none' do
    TaxonConcept.should_receive(:count_by_sql).and_return(0)
    TocItem.should_not_receive(:common_names)
    TocItem.toc_for(@taxon.id).should == [@mock_toc, @mock_search_web]
  end

  it 'should add synonyms if there are any'

  it 'should NOT add synonyms if it has none'

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: table_of_contents
#
#  id         :integer(2)      not null, primary key
#  parent_id  :integer(2)      not null
#  label      :string(255)     not null
#  view_order :integer(1)      not null

