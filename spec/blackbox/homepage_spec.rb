require File.dirname(__FILE__) + '/../spec_helper'

describe 'Home page' do

  before :each do
    Scenario.load :foundation
  end

  it 'should say EOL somewhere' do
    request('/').body.should include('EOL')
  end

  it "should have Edward O. Wilson's quote" do
    request('/').body.should include('Imagine an electronic page for each species of organism on Earth')
  end

  # Looking for something to do?

  it 'should include the search box, for names and tags (defaulting to names)'
  it 'should include a login link, and a create-account link, when not logged in'
  # Note - do we *really* want the preferences link there when it's in the nav bar?
  it 'should have "Hello [username]", a preferences link, a logout link, and vetted status when logged in'
  it 'should have a language picker with all active languages'
  it 'should have all the feedback links'
  it 'should have all the press room links'
  it 'should have all the faq links'
  it 'should have all the about links'
  it 'should show all unique explore taxa, not all fish'
  it 'should show linked scientific names, and (when available) common names in explore taxa'
  it 'should show left page content'
  it 'should show main page content'
  it 'should show news, when news exists'
  it 'should not show news, when no news exists'
  it 'should have an RSS link'
  it 'should show random featured taxoni with medium thumb and linked name'
end
