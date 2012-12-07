require File.dirname(__FILE__) + '/../spec_helper'
require 'capybara'

include ActionController::Caching::Fragments

describe 'Home page' do
  it 'should load', :js => true do
    visit 'http://staging.eol.org'
    page.should have_content('EOL News')
  end
end
