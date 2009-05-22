#!/opt/local/bin/ruby
require 'rubygems'
gem "rspec"
gem "selenium-client"
require "selenium/client"
require "selenium/rspec/spec_helper"

describe "A user who is not logged in" do
  attr_reader :selenium_driver
  alias :page :selenium_driver

  before(:all) do
    @selenium = Selenium::Client::Driver.new \
      :host => "localhost",
      :port => 4444,
      :browser => "*firefox",
      :url => "http://localhost:3000/",
      :timeout_in_second => 60
  end

  before(:each) do
    @selenium.start_new_browser_session
  end

  # The system capture need to happen BEFORE closing the Selenium session
  append_after(:each) do
    @selenium.close_current_browser_session
  end

  it "shouldn't be able to add comments" do
    @selenium.open "/"
    @selenium.click "top_image_tag_1"
    @selenium.wait_for_page_to_load "30000"
    @selenium.click "//a[@id='large-image-comment-button-popup-link']/span"
    60.times{ break if (@selenium.is_text_present("Displaying comments") rescue false); sleep 1 }.should be_nil
    @selenium.is_text_present("You must be logged in to post comments").should be_true
  end

end
