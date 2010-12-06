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
    
  end
end
