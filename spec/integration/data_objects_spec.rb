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
  end
end
