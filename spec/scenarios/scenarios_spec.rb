require "spec_helper"

# make sure our scenarios work!  we want the spec suite to fail
# if any of these scenarios don't work properly.  these are critical
# for the development process and we need to know if someone breaks these!
#
# YES, this spec can take quite a while to run, depending on the number
# of scenarios that we test.  But it's important to explicitly test
# our scenarios and catch if one of them starts raising exceptions.
#
describe EolScenarios do

  before(:all) do
    truncate_all_tables # It is assumed you truncate the tables before you run these (well, before you expect them
                        # to work!)
    EolScenario.load :bootstrap
  end

  it "should have data from foundation loaded" do
    Language.count.should > 1
  end

  it "should have data from bootstrap loaded" do
    User.count.should > 20
  end

  # make sure we are properly catching scenario exceptions!
  it "raises_exception scenario should raise an exception" do
    lambda { EolScenario.load :raises_exception, :whiny => false }.should raise_error
  end

end
