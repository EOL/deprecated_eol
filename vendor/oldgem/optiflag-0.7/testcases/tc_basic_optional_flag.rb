require 'optiflag.rb'
require 'test/unit'

module OptionalArgs extend OptiFlag::Flagset
  flag "dir"
  optional_flag "log"
  optional_flag "verbose_level" do
    value_in_set [1,2,3,4,0]
  end
  optional_switch_flag "force"
end

class TC_OptionalArgs < Test::Unit::TestCase

  def test_none_there
    cl = %w{ -dir c:/my_stuff   }
    result = OptionalArgs::parse(cl)
    assert( ! result.errors?)
    assert_equal("c:/my_stuff",result.flag_value.dir)
    assert(!result.flag_value.log?)
    assert(!result.flag_value.verbose_level?)
    assert(!result.flag_value.force?)
  end
  
  def test_all_there_and_no_errors
    cl = %w{ -dir c:/my_stuff -log c:/log -force -verbose_level 3  }
    result = OptionalArgs::parse(cl)
    assert( ! result.errors?)
    assert_equal("c:/log",result.flag_value.log)
    assert_equal("3",result.flag_value.verbose_level)
    assert(result.flag_value.force?)
  end
  def test_some_there_and_no_errors
    cl = %w{ -dir c:/my_stuff  -force -verbose_level 3  }
    result = OptionalArgs::parse(cl)
    assert( ! result.errors?)
    assert(!result.flag_value.log?)
    assert_equal(nil,result.flag_value.log)
    assert_equal("3",result.flag_value.verbose_level)
    assert(result.flag_value.force?)
  end
  def test_some_there_and_no_errors_rearranged_1
    cl = %w{ -dir c:/my_stuff  -verbose_level 3    -force}
    result = OptionalArgs::parse(cl)
    assert( ! result.errors?)
    assert(!result.flag_value.log?)
    assert_equal(nil,result.flag_value.log)
    assert_equal("3",result.flag_value.verbose_level)
    assert(result.flag_value.force?)
  end
  def test_some_there_and_no_errors_rearranged_2
    cl = %w{  -force -dir c:/my_stuff  -verbose_level 3   }
    result = OptionalArgs::parse(cl)
    assert( ! result.errors?)
    assert(!result.flag_value.log?)
    assert_equal(nil,result.flag_value.log)
    assert_equal("3",result.flag_value.verbose_level)
    assert(result.flag_value.force?)
  end
  def test_some_there_but_has_validation_error
    cl = %w{  -dir c:/my_stuff  -verbose_level three   }
    result = OptionalArgs::parse(cl)
    assert( result.errors?)
    assert(!result.flag_value.log?)
    assert_equal(nil,result.flag_value.log)
    assert(!result.flag_value.force?)
    assert_equal(0,result.errors.missing_flags.length)
    assert_equal(1,result.errors.validation_errors.length)
  end

  

end

