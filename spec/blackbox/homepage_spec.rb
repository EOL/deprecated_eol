require File.dirname(__FILE__) + '/../spec_helper'

include ActionController::Caching::Fragments

def content_section_tester(section_name)
  sec = ContentSection.find_by_name(section_name)
  sec.should_not be_nil
  new_title = Faker::Lorem.words[0]
  ContentPage.gen(:content_section => sec, :title => new_title)
  pages = ContentSection.find_pages_by_section(section_name)
  pages.map(&:title).should include(new_title)
  body = RackBox.request('/').body
  # <a title="Feedback" id="feedback" class="dropdown">Feedback</a>
  body.should have_tag("a##{section_name.downcase.gsub(' ', '_')}", :text => /#{section_name}/)
  # <a href=\"/content/page/contact_us\" target=\"_self\" title=\"Contact Us\">Contact Us</a>
  pages.each {|page| body.should have_tag('a[href=?]', '/content/page/' + page.page_url, :text => page.title ) }
end

describe 'Home page' do

  before :all do
    Scenario.load :foundation
    @homepage_with_foundation = RackBox.request('/') # cache the response the homepage gives before changes
  end
  after :all do
    truncate_all_tables
  end

  it 'should say EOL somewhere' do
    @homepage_with_foundation.body.should include('EOL')
  end

  it "should have Edward O. Wilson's quote" do
    @homepage_with_foundation.body.should include('Imagine an electronic page for each species of organism on Earth')
  end

  it 'should include the search box, for names and tags (defaulting to names)' do
    @homepage_with_foundation.body.should have_tag('form') do
      with_tag('.search_box') do
        with_tag('input#q')
      end
      with_tag('div.search_options') do
        with_tag('input[checked=?][value=?]', 'checked', 'text')
        with_tag('input[value=?]', 'tag')
      end
    end
  end

  it 'should include a "personal-space" div with login link and a create-account link, when not logged in' do
    @homepage_with_foundation.body.should have_tag('div#personal-space') do
      with_tag('a[href*=?]', /\/login/)
      with_tag('a[href*=?]', /\/register/)
    end
  end

  it 'should have desc-personal tag with "Hello [username]", a preferences link, a logout link, and vetted status when logged in' do
    user = User.gen(:password => 'wibbly-wobbly')
    login_as :username => user.username, :password => 'wibbly-wobbly'
    body = RackBox.request('/').body
    body.should have_tag('div#personal-space') do
      with_tag('div.desc-personal', :text => /Hello,?\s+#{user.given_name}/) do
        with_tag('a[href=?]', '/profile?return_to=%252F')  # I could not for the life of me get the regex to work.
        with_tag('a[href*=?]', /logout/)
      end
      without_tag('a[href*=?]', /\/login/)
    end
  end

  it 'should have a language picker with all active languages' do
    en = Language.english
    # Let's add a new language to be sure it shows up:
    Language.gen(:name => 'Supernal', :iso_639_1 => 'sp', :activated_on => 24.hours.ago )
    active = Language.find_active
    active.map(&:name).should include('Supernal')
    body = RackBox.request('/').body
    # <a title=\"Language: en\" class=\"dropdown\">Language: en</a>
    body.should have_tag('a[title=?]', "Language: #{en.iso_639_1}")
    # <a href=\"http://example.org/set_language?language=sp&amp;return_to=%252F\" title=\"Supernal\">Supernal<em>(SP)</em></a>
    active.each {|language| body.should have_tag('a[href*=?]', /set_language.*language=#{language.iso_639_1}/,
                                                 :text => /#{language.name}.*#{language.iso_639_1}/i)  }  
  end


 it 'should have all the feedback links' do
   content_section_tester('Feedback')
 end

 it 'should have all the press room links' do
   content_section_tester('Press Room')
 end

  it 'should have all the using-the-site links' do
    content_section_tester('Using The Site')
  end

  it 'should have all the about-eol links' do
    content_section_tester('About EOL')
  end

  it 'should show six random taxa with the div IDs that the Flash needs' do
    6.times { RandomTaxon.gen }
    body = RackBox.request('/').body
    body.should have_tag('table#top-photos-table') do
      (1..6).to_a.each do |n|
        with_tag("a#top_image_tag_#{n}_href") 
        with_tag("img#top_image_tag_#{n}") 
        with_tag("span#top_name_#{n}") 
      end
    end
  end

  it 'should show left page content' do
    @homepage_with_foundation.body.should include(ContentPage.find_by_title('Home').left_content)
  end

  it 'should show main page content' do
    @homepage_with_foundation.body.should include(ContentPage.find_by_title('Home').main_content)
  end

  it 'should show "What\'s New" (plus news items), when news exists' do
    NewsItem.gen(:title => 'Mars Attacks!')
    body = RackBox.request('/').body
    body.should include('What\'s New?')
    body.should include('Mars Attacks!')
  end

  it 'should not show news, when no news exists' do
    NewsItem.delete_all
    body = RackBox.request('/').body
    body.should_not include('What\'s New?')
  end

  it 'should have an RSS link (if there is news)' do
    NewsItem.gen(:title => 'Mars Attacks!')
    RackBox.request('/').body.should have_tag('a[href=?]', '/content/news?format=rss')
  end

end

# This one doesn't work yet. ...It thinks that the include in bootstrap.rb is a class, not a module.  I didn't have the time to
# figure that out, so I commented this out.  ...Not sure this would work even if that were fixed--I haven't had a chance to try it
# when it works!
#
#describe 'Home page with bootstrapped DB' do
#
#  scenario :foundation, :bootstrap
#
#  it 'should show random featured taxon with medium thumb and linked name' do
#    tc = TaxonConcept.find(6) # Doesn't *really* matter, but I happen to know 6 is well-fleshed-out.
#    TaxonConcept.should_receive(:exemplars).and_return([tc])
#    body = request('/').body
#    body.should include('Featured')
#    body.should have_tag('a', :text => tc.quick_scientific_name(:italicized))
#    body.should have_tag('img[src=?]', tc.smart_medium_thumb)
#  end
#
#end
