require File.dirname(__FILE__) + '/selenium_spec_helper'

describe "A user who is not logged in" do

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

  it "should click images" do
    @page.open "/"
    @page.click "link=About EOL"
    @page.is_text_present("Imagine an electronic page").should be_true
  end

end

