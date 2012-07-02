require File.dirname(__FILE__) + '/../spec_helper'

include ActionController::Caching::Fragments

describe 'Home page' do

  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
    visit('/') # cache the response the homepage gives before changes
    @homepage_with_foundation = source #source in contrast with body returns html BEFORE any javascript
  end

  after :all do
    truncate_all_tables
  end

  it "should provide consistent canonical URL for home page" do
    canonical_href = root_url.sub(/\/+$/,'')
    @homepage_with_foundation.should have_tag('link[rel=canonical][href=?]', canonical_href)
    visit '/?page=3&q=blah'
    body.should have_tag('link[rel=canonical][href=?]', canonical_href)
  end

  it "should not have rel prev or next link tags" do
    visit '/?page=3'
    body.should_not have_tag('link[rel=?]', /(prev|next)/)
  end

  it 'should say EOL somewhere' do
    @homepage_with_foundation.should include('EOL')
  end

  it 'should include the search box, for names and tags (defaulting to names)' do
    @homepage_with_foundation.should have_tag('form') do
      with_tag('#simple_search') do
        with_tag('input#q')
      end
    end
  end

  it 'should include a login link and join link, when not logged in' do
    @homepage_with_foundation.should have_tag('#header') do
      with_tag('a[href*=?]', /\/login/)
      with_tag('a[href*=?]', /\/register/)
    end
  end

  it 'should include logout link and not login link, when logged in'
#    @homepage_with_foundation.should     have_tag('#header a[href*=?]', /login/)
#    @homepage_with_foundation.should_not have_tag('#header a[href*=?]', /logout/)
#    login_as User.gen
#    visit('/')
#    body.should_not have_tag('#header a[href*=?]', /login/)
#    visit('/')
#    body.should     have_tag('#header a[href*=?]', /logout/)
#    visit('/logout')

  it 'should have a language picker with all approved languages' do
    en = Language.english
    # Let's add a new language to be sure it shows up:
    Language.gen_if_not_exists(:iso_639_1 => 'es', :label => 'Spanish')
    Language.gen_if_not_exists(:iso_639_1 => 'ar', :label => 'Arabic')
    active = Language.approved_languages
    visit('/')
    active.each do |language|
      if language.iso_639_1 == I18n.locale.to_s
        body.should have_tag('.language p a span', :text => language.source_form)
      else
        body.should have_tag('.language a[href*=?]', /set_language.*language=#{language.iso_639_1}/,
                              :text => language.source_form)
      end
    end
  end

  it "should have 'Help', 'What is EOL?', 'EOL News', 'Donate' links" do
    visit('/')
    ['Help', 'What is EOL?', 'EOL News', 'Donate'].each do |link|
      body.should have_tag("#header a", link)
    end
  end

  it 'should show the March of Life'
    #Capybara.reset_sessions!
    #6.times { RandomHierarchyImage.gen(:hierarchy => Hierarchy.default) }
    #visit('/')

    #body.should have_tag('.thumbnails') do
      #(1..6).to_a.each do |n|
        # TODO - This will be changed soon.  Re-write.  Note that *possibly* the 6.times {} clause above isn't enough...
        # perhaps something needs to be re-indexed, because on some runs, this ends up with only 4 images.
      #end
    #end

  it 'should show a statistical summary of what is currently in EOL'

  it 'should show recent updates'

end

