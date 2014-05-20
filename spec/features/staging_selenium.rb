# encoding: utf-8
#
# You run this with:
#
#    LOCALE=active rspec spec/features/staging_selenium.rb --format documentation
#
require File.dirname(__FILE__) + '/../spec_helper'
require 'capybara'
require 'capybara-webkit'
include ActionController::Caching::Fragments

# All kinds of special setup:
#Capybara.current_driver = :mechanize
Capybara.javascript_driver = :webkit
Capybara.app_host = Rails.configuration.acceptance_host[:url]
Capybara.run_server = false # Don't bother spinning up *our* server!

# NOTE - *Important* ... you should need some configuration for these specs to work. Edit your
# config/environments/local.rb file and add something like this:
# Rails.configuration.acceptance_curator = {username: 'curator', password: 'I love life'}
# Rails.configuration.acceptance_host = {url: 'http://staging_testss.eol.org', username: 'restricted', password: 'secure!'}

describe 'Staging', js: true do

  def visit_with_auth(where)
    puts "++ Heading to #{where}"
    page.driver.browser.authenticate(Rails.configuration.acceptance_host[:username],
                                     Rails.configuration.acceptance_host[:password])
    visit where
    puts "   ... Done."
  end

  describe 'Languages' do
    after(:all) do
      visit_with_auth "/set_language?language=en"
      I18n.locale = :en
    end

   Language.approved_languages.each do |lang|
      it "should minimally support #{lang}" do
        I18n.locale = lang
        visit_with_auth "/set_language?language=#{lang}"
        visit_with_auth "/"
        page.should have_content(I18n.t(:global_access_tagline))
        visit_with_auth "/pages/7659/overview"
        page.should have_content('Delphinidae')
        page.should have_content(I18n.t(:learn_more_about_names_for_this_taxon))
      end
    end

  end

  it 'should load' do
    visit_with_auth "/set_language?language=en"
    visit_with_auth '/'
    page.should have_content('EOL News')
  end

  it 'should find tiger' do
    visit_with_auth "/search?q=tiger"
    page.should have_content("You've arrived here by searching for tiger.")
    click_link "Click here to see other search results."
    page.should have_content("Panthera tigris")
    page.should have_content("Displaying 1 – 25 of") # I don't care how many, as long as > 25.
    click_link "see next 25"
    page.should have_content("Displaying 26 – 50 of") # Still don't care how many.
    check "type_taxon_concept"
    click_button "Filter"
    expect(page).to have_tag('.hgroup', text: /[^0-9]\d{3} results for/)
  end

  it 'should find jrice' do
    visit_with_auth "/search?q=jrice"
    # <h2>6 results for <em>jrice</em></h2>
    within('#page_heading') do
      expect(page).to have_tag('em', text: /jrice/) # Not the best test, but was having trouble searching for /d results within...
    end
    click_link "jrice"
    page.should have_content "Activity"
    page.should have_content "My info"
  end

  it 'should have a what is EOL link' do
    visit_with_auth "/"
    click_link "What is EOL?"
    page.should have_content "Mission"
  end

  it 'should have a podcasts link' do
    visit_with_auth "/"
    click_link "Podcasts"
    page.should have_content "Black-tailed prairie dogs"
  end

  it 'should have old updates on dato pages' do
    visit_with_auth "/data_objects/21078282"
    page.should have_content %q{Tracy Barbaro added an association between "Nile Crocodile, Botswana" } +
       %q{and "Crocodylus niloticus Laurenti, 1768"}
    page.should have_content %q{Tracy Barbaro commented on an older version of Nile Crocodile, Botswana}
  end

  it 'should have a contact us page' do
    visit_with_auth "/contact_us"
    page.should have_content 'Your name'
    page.should have_content 'Your email'
    page.should have_content 'Subject'
    page.should have_content 'Your message'
    page.should have_selector 'div#recaptcha_widget_div'
    click_button 'Send feedback'
    page.should have_content 'Message can\'t be blank'
  end

  it 'should NOT have a reindex page button' do
    visit_with_auth "/pages/339201/overview"
    expect(page).not_to have_tag('a.button', text: I18n.t(:reindex_page_button))
  end

  # ARGH!  I cannot get a context / describe block to work, so I'm doing it the hard way:
  it 'full curator should have a reindex page button' do
    visit_with_auth "/login"
    fill_in 'session_username_or_email', with: Rails.configuration.acceptance_curator[:username]
    fill_in 'session_password', with: Rails.configuration.acceptance_curator[:password]
    click_button 'Sign in'
    visit_with_auth "/pages/339201/overview"
    expect(page).to have_tag('a.button', text: I18n.t(:reindex_page_button))
    visit_with_auth "/logout"
  end

  it 'should handle comments correctly' do
    visit_with_auth "/logout"
    visit_with_auth "/users/1/newsfeed"
    test_text = "Whatever dude, #{FactoryGirl.generate(:string)} #{rand(100)} #{rand(100)} " # Otherwise we get a duplicate warning...
    bad_text = 'QWERQWERQWER'
    more_text = 'Yay!'
    link_stuff = 'http://whatever.org and one starting with www.google.com and a third marked up using <a href="something.edu">this</a>.'
    fill_in 'comment_body', with: test_text + link_stuff
    click_button 'Post Comment'
    fill_in 'session_username_or_email', with: Rails.configuration.acceptance_curator[:username]
    fill_in 'session_password', with: Rails.configuration.acceptance_curator[:password]
    click_button 'Sign in'
    page.should have_content test_text # It won't have link_stuff 'cause it's too long...
    page.should have_content I18n.t(:comment_added_notice)
    within("ul.feed") do
      page.should have_selector 'a[href="http://whatever.org"]'
      page.should have_selector 'a[href="http://www.google.com"]'
      page.should have_selector 'a[href="something.edu"]', text: 'this'
      click_link 'edit' # There should only be one...
      fill_in 'comment_body', with: bad_text
      click_link 'Cancel'
      page.should_not have_content bad_text
      click_link 'edit'
      fill_in 'comment_body', with: more_text
      click_button 'save comment'
      page.should have_content more_text
      click_link 'edit'
      click_link 'Cancel'
      page.driver.accept_js_prompts!
      click_button 'delete'
      page.should_not have_content more_text
    end
  end

end
