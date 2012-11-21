require File.dirname(__FILE__) + '/../spec_helper'

describe 'CMS' do

  before :all do
    # We use 'about' so we can test routes and canonical URLs i.e. /about
    # If 'about' is generated in a previous spec then specs in this file may fail e.g. if @content_page_about.active is false
    unless @content_page_about = ContentPage.find_by_page_name("about", :include => :translations)
      truncate_all_tables
      load_foundation_cache
      @content_page_about = ContentPage.gen(:active => true, :page_name => "about")
      TranslatedContentPage.gen(:content_page => @content_page_about, :active_translation => true)
    end
  end

  describe 'page' do

    it 'should provide a consistent canonical URL' do
      canonical_href = cms_page_path(@content_page_about)
      visit "/about"
      page.should have_tag("link[rel='canonical'][href$='#{canonical_href}']")
      visit "/info/#{@content_page_about.id}"
      page.should have_tag("link[rel='canonical'][href$='#{canonical_href}']")
      visit "/info/#{@content_page_about.page_name}"
      page.should have_tag("link[rel='canonical'][href$='#{canonical_href}']")
      visit cms_page_path(@content_page_about, :page => 3, :q => "blah")
      page.should have_tag("link[rel='canonical'][href$='#{canonical_href}']")
    end

    it 'should not have rel prev or next link tags' do
      visit cms_page_url(@content_page_about, :page => 3)
      page.should_not have_tag("link[rel='prev']")
      page.should_not have_tag("link[rel='next']")
    end

  end
end
