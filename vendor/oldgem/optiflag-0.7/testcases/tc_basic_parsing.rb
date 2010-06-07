require 'optiflag.rb'
require 'test/unit'

module DansArgs extend OptiFlag::Flagset
  flag ["directory"]
  flag "script"
  flag ["control_db"] do
    description "The control database credentials"
  end
  flag ["target_db"]
end

class TC_FlagAll < Test::Unit::TestCase

  def setup
    @regular_dans_args = %w{-directory my_directory -script my_script 
              -control_db control -target_db target}
    @missing_dans_args = %w{-directory my_directory -script my_script}
  end

  def test_regular_dans_arg_parses
    result = DansArgs::parse(@regular_dans_args)
    assert_equal("my_directory",result.flag_value.directory,
           "Flag should be equal to my_directory")
    assert(result.flag_value.directory?,
           "Directory Flag should have been passed")
    assert_equal("my_script",result.flag_value.script,
           "Flag should be equal to my_script")
    assert_equal("control",result.flag_value.control_db,
           "Flag should be equal to control")
    assert(result.errors? == false,"There should be no errors")
  end

  def test_missing_dans_arg_parses
    result = DansArgs::parse(@missing_dans_args)
    assert( result.errors?,  
            "There should be errors, with two missing required options")
    assert_equal("-control_db",result.errors.missing_flags[0], 
           "First Missing flag should be -control_db")
    assert_equal("-target_db",result.errors.missing_flags[1],
           "Second Missing flag should be -target_db")
    assert_equal(2,result.errors.missing_flags.length,
           "There should be two missing flags")
  end

  def teardown

  end

end

