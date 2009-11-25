require 'optiflag.rb'
require 'test/unit'

module BugTwoArgs extend OptiFlag::Flagset
  flag "dir"
  optional_flag "log"
  optional_flag "verbose_level" do
    value_in_set [1,2,3,4,0]
  end
  optional_switch_flag "force"
  usage_flag "h"
end

class TC_BugTwo < Test::Unit::TestCase


  def setup
    # this thing is changing global state
    cl = %w{ -dir c:/my_stuff -log c:/log -force -verbose_level 3 -h }
    result = BugTwoArgs::parse(cl)
  end

  def test_a
    cl = %w{ -dir c:/my_stuff   }
    result = BugTwoArgs::parse(cl)
    assert(!result.help_requested?,"Help was not requested")
    assert(!result.flag_value.log?)

    assert(!result.flag_value.verbose_level?)
    assert(!result.flag_value.force?)
  end
end

