require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do

  before(:all) do
    load_foundation_cache
    @tc = build_taxon_concept
    @tc_comment = @tc.comments[0]
    @text_comment = @tc.data_objects.select { |d| d.is_text? && !d.comments.blank? }.first.comments.first
    # If this next line fails, something went wrong with Solr building data... Perhaps we should reindex, here?
    @image_comment = @tc.data_objects.select { |d| d.is_image? && !d.comments.blank? }.first.comments.first
    @invisible_comment = Comment.gen(:parent => DataObject.last, :visible_at => 4.days.from_now)
    @curator = User.find(@tc.curators[0])
    @non_curator = User.gen
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  before(:each) do
    @tc_comment.visible_at = 1.second.ago
    @tc_comment.save
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
    [1.minute.from_now, 1.day.from_now, 1.year.from_now].each do |timestamp|
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
    image = @tc.images_from_solr(1, :skip_preload => false)[0]
    image.comments[0].parent_name.should == image.description
  end

  it "should return parent type if comment is for object that is not TaxonConcept or DataObject" do
    comment = Comment.gen(:parent => @tc.images_from_solr.first)
    comment.parent_type = 'Language'
    comment.save
    comment.reload.parent_name.should == 'Language'
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

  # show
  it "should add curator who vetted object and make comment visible" do
    @invisible_comment.show(@curator)
    @invisible_comment.visible?.should be_true
    @invisible_comment.vetted_by.should == @curator
  end

  # hide
  it "should add curator who vetted object and make comment visible" do
    tc_comment = Comment.gen(:parent => DataObject.last)
    tc_comment.visible_at = 1.day.ago
    tc_comment.vetted_by.should_not == @curator
    tc_comment.save
    tc_comment.visible?.should be_true
    tc_comment.hide(@curator)
    tc_comment.visible?.should be_false
    tc_comment.vetted_by.should == @curator
  end

  # taxon_concept_id
  it "should return TaxonConcept id for different types of comments" do
    @tc_comment.taxon_concept_id.should == @tc.id
    @image_comment.taxon_concept_id.should == @tc.id
    @text_comment.taxon_concept_id.should == @tc.id
  end
end
