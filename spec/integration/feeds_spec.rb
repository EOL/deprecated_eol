require File.dirname(__FILE__) + '/../spec_helper'

def h(str)
  CGI.escapeHTML str
end

describe 'Feeds' do

  describe 'Curator Feeds' do
    before(:all) do
      truncate_all_tables
      load_foundation_cache
      Capybara.reset_sessions!
      DataObject.delete_all
      Comment.delete_all
      @tc = build_taxon_concept()
      @text = @tc.data_objects.select{|d| d.data_type_id == DataType.text.id}
      @images = @tc.data_objects.select{|d| d.data_type_id == DataType.image.id}
      @feeds = ["/feeds/text/", "/feeds/images/", "/feeds/comments/", "/feeds/all/"]
    end

    after(:all) do
      truncate_all_tables
    end

    it "should render: 'text', 'images', 'comments', 'all' feeds" do
      @feeds.each do |feed_url|
        visit("#{feed_url}#{@tc.id}")
        page.status_code.should == 200
        body.should have_tag("feed")
      end
    end

    it "should show information in a time descentind order" do
      @feeds.each do |feed_url|
        visit(feed_url)
        dates = Nokogiri.XML(body).xpath("//xmlns:updated").map {|i| Time.parse(i.text)}
        dates.should == dates.sort.reverse
      end
    end

    # this test is strange. the whole spec could use rewriting
    # it "should should only information about a specific species if species are selected" do
    #   #Brittle test, may be is should be removed...
    #   # Wish we had a better way to see if all info is about the same species.
    #   # Picking species name from the title and mangle it to get a canonical name
    #
    #   res = request("/feeds/all/#{@tc.id}")
    #   titles =  Nokogiri.XML(res.body).xpath("//xmlns:title").map {|i| i.text.match /new\s+(image|text|comment|)\s+for\s+(.*)\s*$/i}
    #   titles = titles.select {|i| i}.map {|i| i[2].strip.split(/\s+/)[0..1].join(" ")}
    #   titles.uniq.size.should == 1
    # end

    #  it 'should verify that comments feed for a species with no childen in tree only has comment for that species'

    #  it 'should verify that images feed for a species with no childen in tree only has images for that species'
    #  it 'should verify that text feed for a species with no childen in tree only has text for that species'
    #
    #  it 'should verify that comments feed for a species with childen in the tree has comments for itself and all its children'
    #  it 'should verify that images feed for a species with childen in the tree has images for itself and all its children'
    #  it 'should verify that text feed for a species with childen in the tree has text for itself and all its children'
    #
    #  it 'should verify that comments feed has comments for old and new version of re-harvested data'

    it 'should verify that all feed contains text, images, and comments' do
      visit("/feeds/all/#{@tc.id}")
      body.should include(h @text[0].description)
      body.should include(h @images[0].description)
      #body.downcase.should include('new comment')

      #visit("/feeds/all/")
      #body.downcase.should include('new image')  don't get any images in first 100 results
      #body.downcase.should include('new text')
      #body.downcase.should include('new comment')
    end

  end


  describe ': content partner curated data' do
    before(:all) do
      truncate_all_tables
      load_foundation_cache

      @user = User.gen(:given_name => 'FishBase')
      @content_partner = ContentPartner.gen(:user => @user)
      @resource = Resource.gen(:title => "test resource", :content_partner => @content_partner)
      last_month = Time.now - 1.month
      @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month)
      @data_object = DataObject.gen(:published => 1, :vetted_id => Vetted.trusted.id)
      @data_objects_harvest_event = DataObjectsHarvestEvent.gen(:data_object_id => @data_object.id, :harvest_event_id => @harvest_event.id)

      @taxon_concept = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
      @data_objects_taxon_concept = DataObjectsTaxonConcept.gen(:data_object_id => @data_object.id, :taxon_concept_id => @taxon_concept.id)

      @action_with_object = ActionWithObject.gen_if_not_exists(:action_code => 'trusted')
      @changeable_object_type = ChangeableObjectType.gen_if_not_exists(:ch_object_type => 'data_object')
      @action_history = CuratorActivityLog.gen(:object_id => @data_object.id, :action_with_object_id => @action_with_object.id, :changeable_object_type_id => @changeable_object_type.id)
    end

    it "should show feed with all curation activity for a content partner" do
      visit("/feeds/partner_curation?user_id=#{@user.id}")
      body.should include "#{@user.full_name} curation activity"
    end

    it "should show feed for a month's curation activity for a content partner" do
      last_month = Time.now - 1.month
      @report_year = last_month.year.to_s
      @report_month = last_month.month.to_s
      @year_month   = @report_year + "_" + "%02d" % @report_month.to_i
      visit("/feeds/partner_curation?user_id=#{@user.id}&year_month=#{URI.escape @year_month}")
      body.should include "#{@user.full_name} curation activity"
    end
  end

end





