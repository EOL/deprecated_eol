require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonContentSection do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @overview = TaxonContentSection.overview
  end

  it 'should create the overview in the foundation scenario' do
    @overview.name.should =~ /overview/i
  end

  it '(overview) should have a few toc_items in its #content' do
    @overview.toc_items.include?(TocItem.distribution).should be_true
    @overview.toc_items.include?(TocItem.brief_summary).should be_true
    @overview.toc_items.include?(TocItem.comprehensive_description).should be_true
  end

end
