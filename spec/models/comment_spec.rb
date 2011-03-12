require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do 

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @tc = build_taxon_concept()
    @tc_comment = @tc.comments[0]
    @text_comment = @tc.data_objects.select { |d| d.data_type.label == 'Text'  }.select { |t| !t.comments.blank? }.first.comments.first
    @image_comment = @tc.images.select { |i| !i.comments.blank? }.first.comments.first
    @curator = @tc.curators[0]
    @non_curator = User.gen
  end
    
  # for_feeds
  it 'should find text data objects for feeds' do
    res = Comment.for_feeds(:comments, @tc.id)
    res.class.should == Array
    res_type = res.map {|i| i.class}.uniq
    res_type.size.should == 1
    res_type[0].should == Hash
  end

  # visible?
  it "should return true if visible_at date is in the past" do
    [1.second.ago, 1.day.ago, 1.year.ago].each do |timestamp|
      @tc_comment.visible_at = timestamp
      @tc_comment.save
      @tc_comment.reload.visible?.should be_true
    end
  end

  it "should return false if visible_at date is in the future" do
    [1.second.from_now, 1.day.from_now, 1.year.from_now].each do |timestamp|
      @tc_comment.visible_at = timestamp
      @tc_comment.save
      @tc_comment.reload.visible?.should be_false
    end
  end

  it "should return false if visible_at is nil" do
    @tc_comment.is_a?(::Comment).should be_true
    @tc_comment.visible_at = nil
    @tc_comment.save
    @tc_comment.reload.visible?.should be_false
  end

  # parent_name
  it "should return taxon concept name for TaxonConcept comment" do
    @tc_comment.parent_name.should == @tc.entry.name.string
  end

  it "should return dato description for DataObject comment" do
    @tc.images[0].comments[0].parent_name.should == @tc.images[0].description
  end

  it "should return parent type if comment is for object that is not TaxonConcept or DataObject" do
    comment = @tc.images[0].comments[0]
    comment.parent_type = 'UnkownType'
    comment.save
    comment.reload.parent_name.should == 'UnkownType'
    comment.parent_type = "DataObject"
    comment.save
  end

  # taxa_comment
  it "should be true for TaxonConcept comment" do
    @tc_comment.taxa_comment?.should be_true
  end
  
  it "should be false for non TaxonConcept comment" do
    @image_comment.taxa_comment?.should be_false
  end

  # image_comment
  it "should be true for Image comment" do
    @image_comment.image_comment?.should be_true
  end
  
  it "should be false for non Image comment" do
    @tc_comment.image_comment?.should be_false
  end
  
  # text_comment
  it "should be true for Text comment" do
    @text_comment.text_comment?.should be_true
  end
  
  it "should be false for non Text comment" do
    @image_comment.text_comment?.should be_false
  end

  # parent_image_url
  it "should return url for image object" do
    url_path = /http:\/\/[^\/]+/
    @image_comment.parent_image_url.gsub(url_path, '').should == @image_comment.parent.smart_thumb.gsub(url_path, '')
  end

  it "should return empty string for non image object" do
    @text_comment.parent_image_url.should == ''
  end

  # parent_url
  it "should return taxon page for TaxonConcept" do
    @tc_comment.parent_url.should == "/pages/#{@tc.id}"
  end

  it "should return data_object page for DataObject" do
    @image_comment.parent_url.should == "/data_objects/#{@image_comment.parent.id}"
    @text_comment.parent_url.should == "/data_objects/#{@text_comment.parent.id}"
  end

  # parent_type_name
  it "should return 'page' for TaxonConcept" do
    @tc_comment.parent_type_name.should == 'page'
  end

  it "should return 'image' for Image dato" do
    @image_comment.parent_type_name.should == 'image'
  end

  it "should return 'text' for Text dato" do
    @text_comment.parent_type_name.should == 'text'
  end

  # is_curatable_by
  it "should return true for a curator of it's parent" do
    @tc_comment.is_curatable_by?(@curator).should be_true
  end

  it "should return false for a non-curator of it's parent" do
    @tc_comment.is_curatable_by?(@non_curator).should be_false
  end

  # show
  it "should add curator who vetted object, log curator activity, and make comment visible" do
    @tc_comment.visible_at = nil
    @tc_comment.vetted_by.should_not == @curator
    @tc_comment.save
    audit_count = ActionsHistory.count
    @tc_comment.visible?.should be_false
    @tc_comment.show(@curator)
    @tc_comment.visible?.should be_true
    @tc_comment.vetted_by.should == @curator
    (ActionsHistory.count - audit_count).should == 1
    ActionsHistory.last.user.should == @curator
  end 
    
  # hide
  it "should add curator who vetted object, log curator activity, and make comment visible" do
    @tc.comments.delete_all
    @tc_comment = Comment.gen(:parent_id => @tc.id, :parent_type => 'TaxonConcept')
    @tc_comment.visible_at = 1.day.ago
    @tc_comment.vetted_by.should_not == @curator
    @tc_comment.save
    audit_count = ActionsHistory.count
    @tc_comment.visible?.should be_true
    @tc_comment.hide(@curator)
    @tc_comment.visible?.should be_false
    @tc_comment.vetted_by.should == @curator
    (ActionsHistory.count - audit_count).should == 1
    ActionsHistory.last.user.should == @curator
  end

  # curator_activity_flag
  it "should add a curator activity flag if comment is created by curator" do
    activity_flag_count = LastCuratedDate.count
    @tc_comment.user = @curator
    @tc_comment.save
    @tc_comment.reload.curator_activity_flag
    (LastCuratedDate.count - activity_flag_count).should == 1
  end

  it "should not add a curator activity flag if comment is created by non-curator" do
    activity_flag_count = LastCuratedDate.count
    @tc_comment.user = @non_curator
    @tc_comment.save
    @tc_comment.reload.curator_activity_flag
    (LastCuratedDate.count - activity_flag_count).should == 0
  end

  # taxon_concept_id
  it "should return TaxonConcept id for different types of comments" do
    @tc_comment.taxon_concept_id.should == @tc.id
    @image_comment.taxon_concept_id.should == @tc.id
    @text_comment.taxon_concept_id.should == @tc.id
  end
end
