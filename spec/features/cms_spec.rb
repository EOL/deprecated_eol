require "spec_helper"

describe 'CMS' do

  before :all do
    # We use 'about' so we can test routes and canonical URLs i.e. /about
    # If 'about' is generated in a previous spec then specs in this file may fail e.g. if @content_page_about.active is false
    unless @content_page_about = ContentPage.find_by_page_name("about", include: :translations)
      load_foundation_cache
      @content_page_about = ContentPage.gen(active: true, page_name: "about")
      TranslatedContentPage.gen(content_page: @content_page_about, active_translation: true)
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
      visit cms_page_path(@content_page_about, page: 3, q: "blah")
      page.should have_tag("link[rel='canonical'][href$='#{canonical_href}']")
    end

    it 'should not have rel prev or next link tags' do
      visit cms_page_url(@content_page_about, page: 3)
      page.should_not have_tag("link[rel='prev']")
      page.should_not have_tag("link[rel='next']")
    end

    it 'should use meta description and keyword fields' do
      content_page = ContentPage.gen(active: true, page_name: "Testing Meta Tags")
      english_translation = TranslatedContentPage.gen(content_page: content_page, active_translation: true, language: Language.english,
        meta_keywords: nil, meta_description: nil)
      visit "/info/#{content_page.id}"
      page.should_not have_tag("meta[name='keywords']")
      page.should_not have_tag("meta[name='description']")
      page.should_not have_tag("meta[property='og:description']")

      english_translation.meta_keywords = "Some English keywords"
      english_translation.meta_description = "Some English description"
      english_translation.save!
      visit "/info/#{content_page.id}"
      page.should have_tag("meta[name='keywords'][content='#{english_translation.meta_keywords}']")
      page.should have_tag("meta[name='description'][content='#{english_translation.meta_description}']")
      page.should have_tag("meta[property='og:description'][content='#{english_translation.meta_description}']")

      arabic_translation = TranslatedContentPage.gen(content_page: content_page, active_translation: true, language: Language.from_iso('ar'),
        meta_keywords: nil, meta_description: nil)
      visit('/set_language?language=ar')
      visit "/info/#{content_page.id}"
      # meta tags are specific to language, so the Arabic article won't start out with any
      page.should_not have_tag("meta[name='keywords']")
      page.should_not have_tag("meta[name='description']")
      page.should_not have_tag("meta[property='og:description']")

      arabic_translation.meta_keywords = "Some Arabic keywords"
      arabic_translation.meta_description = "Some Arabic description"
      arabic_translation.save
      visit "/info/#{content_page.id}"
      page.should have_tag("meta[name='keywords'][content='#{arabic_translation.meta_keywords}']")
      page.should have_tag("meta[name='description'][content='#{arabic_translation.meta_description}']")
      page.should have_tag("meta[property='og:description'][content='#{arabic_translation.meta_description}']")
    end
  end
end
