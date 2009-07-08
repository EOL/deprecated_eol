require File.dirname(__FILE__) + '/../spec_helper'

# make sure our scenarios work!  we want the spec suite to fail
# if any of these scenarios don't work properly.  these are critical 
# for the development process and we need to know if someone breaks these!
#
# YES, this spec can take quite a while to run, depending on the number 
# of scenarios that we test.  But it's important to explicitly test 
# our scenarios and catch if one of them starts raising exceptions.
#
describe Scenarios do

  before(:all) do
    truncate_all_tables # It is assumed you truncate the tables before you run these (well, before you expect them
                        # to work!)
  end

  # test the scenarios we want to make sure work
  %w( foundation bootstrap ).each do |scenario|
    it "#{scenario} scenario should load without errors" do
      Scenario.load scenario
    end
  end

  # make sure we are properly catching scenario exceptions!
  it "raises_exception scenario should raise an exception" do
    lambda { Scenario.load :raises_exception, :whiny => false }.should raise_error
  end

end
