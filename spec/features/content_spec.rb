require "spec_helper"

describe "Donation" do
  it "should render entry donation page" do
    visit("/donate")
    page.status_code.should == 200
    source.should include "Donate"
  end

  it "should render complete donation page" do
    visit("/content/donate_complete")
    page.status_code.should == 200
    source.should include("Thank you")
  end
end
