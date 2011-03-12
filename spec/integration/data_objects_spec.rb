require File.dirname(__FILE__) + '/../spec_helper'

describe 'Data Object Page' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
  end

  describe "#show" do
    before(:all) do
      @tc = build_taxon_concept(:images => [:object_cache_url => Factory.next(:image)], :toc => []) # Somewhat empty, to speed things up.
      @image = @tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
      # Build data_object without comments
      @dato_no_comments = build_data_object('Image', 'No comments',
      :num_comments => 0,
      :object_cache_url => Factory.next(:image),
      :vetted => Vetted.trusted,
      :visibility => Visibility.visible)
      @dato_comments_no_pagination = build_data_object('Image', 'Some comments',
      :num_comments => 4,
      :object_cache_url => Factory.next(:image),
      :vetted => Vetted.trusted,
      :visibility => Visibility.visible)
      @dato_comments_with_pagination = build_data_object('Image', 'Lots of comments',
      :num_comments => 15,
      :object_cache_url => Factory.next(:image),
      :vetted => Vetted.trusted,
      :visibility => Visibility.visible)
      @dato_untrusted = build_data_object('Image', 'removed', 
      :num_comments => 0,
      :object_cache_url => Factory.next(:image),
      :vetted => Vetted.untrusted,
      :visibility => Visibility.invisible)
    end

    it "should render" do
      visit("/data_objects/#{@image.id}")
      page.status_code.should == 200
    end

    it "should show metainformation about data_object" do
      visit("/data_objects/#{@image.id}")
      page.should have_content("Permalink")
      find(:css, ".credit-value input").value.should == "http://#{$SITE_DOMAIN_OR_IP}/data_objects/#{@image.id}"
    end
    
    it "should show image description for image objects" do
      visit("/data_objects/#{@image.id}")
      body.should include('<h3>Description</h3>')
      body.should include("<div class='description #{@image.id}'>")
      body.should include @image.description
    end
    
    it "should not show comments section if there are no comments" do
      visit("/data_objects/#{@dato_no_comments.id}")
      page.status_code.should == 200
      page.should have_no_xpath("//div[@id='commentsContain']")
    end
    
    it "should not show pagination if there are less than 10 comments" do
      visit("/data_objects/#{@dato_comments_no_pagination.id}")
      page.status_code.should == 200
      page.should have_xpath("//div[@id='commentsContain']")
      page.should have_no_xpath("//div[@id='commentsContain']/div[@id='pagination']")
    end
    
    it "should show pagination if there are more than 10 comments" do
      visit("/data_objects/#{@dato_comments_with_pagination.id}")
      page.status_code.should == 200
      page.should have_xpath("//div[@id='commentsContain']/div[@class='pagination']")
    end

    it "should have a taxon_concept link for untrusted image, but following the link should show a warning" do
      visit("/data_objects/#{@dato_untrusted.id}")
      page.status_code.should == 200
      page_link = "/pages/#{@tc.id}?image_id=#{@dato_untrusted.id}"
      page.body.should include(page_link)
      visit(page_link)
      page.status_code.should == 200
      page.body.should include('Image is no longer available')
    end

    it "should not show a link for data_object if its taxon page is not in database anymore" do
      tc = build_taxon_concept(:images => [:object_cache_url => Factory.next(:image)], :toc => [], :published => false)
      image = tc.data_objects.select { |d| d.data_type.label == "Image" }[0]
      tc.published = false
      tc.save!
      dato_no_tc = build_data_object('Image', 'unlinked',
      :num_comments => 0,
      :object_cache_url => Factory.next(:image),
      :vetted => Vetted.trusted,
      :visibility => Visibility.visible)
      dato_no_tc.get_taxon_concepts[0].published?.should be_false
      visit("/data_objects/#{dato_no_tc.id}")
      page_link = "/pages/#{tc.id}?image_id="
      page.body.should_not include(page_link)
      page.body.should include("associated with the deprecated page")
    end
    
  end
end
