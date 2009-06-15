require File.dirname(__FILE__) + '/selenium_spec_helper'

describe "On /register" do

  before(:all) do
    @page = Selenium::Client::Driver.new(:host => "localhost",
                                         :port => 4444,
                                         :browser => "*firefox",
                                         :url => "http://localhost:3000/",
                                         :timeout_in_second => 60)
  end

  before(:each) do
    @page.start_new_browser_session
  end

  # The system capture need to happen BEFORE closing the Selenium session
  append_after(:each) do
    @page.close_current_browser_session
  end

  describe "Users" do
    it "should click the checkbox 'Do you want to be a curator' to display curator options" do
      @page.open "/register"
      @page.is_element_present("//div[@id=\"curator_request_options\" and contains(@style, 'display: none')]").should be_true
      @page.click "curator_request"
      @page.is_element_present("//div[@id=\"curator_request_options\" and contains(@style, '')]").should be_true
      @page.click "curator_request"
      @page.is_element_present("//div[@id=\"curator_request_options\" and contains(@style, 'display: none')]").should be_true
    end

    # Implementation of the previous test w/ is_visible. Waits via sleep(2) which doesn't seem like a great idea
    # it "should click the checkbox 'Do you want to be a curator' to display curator options w/ is_visible" do
    #   @page.open "/register"
    #   @page.is_visible("curator_request_options").should be_false
    #   @page.click "curator_request"
    #   sleep 2
    #   @page.is_visible("curator_request")
    # end
  end

end