require 'optiflag.rb'
require 'test/unit'

module EnumeratedValidArgs extend OptiFlag::Flagset
  flag "directory"
  flag "script", :description => "The Script directory"
  flag "mode" do 
    value_in_set [1,2,"three"]
  end
  
end

class TC_EnumeratedValidArgs < Test::Unit::TestCase

 
  def test_validation
    command_line = %w{-directory c:/eu -script RunMe -mode 1 }
    args = EnumeratedValidArgs::parse(command_line)
    assert_equal("c:/eu",args.flag_value.directory,
                 "Directory not properly set")
    assert(! args.errors?, 
           "No errors should have occurred") 
  end

  def test_validation_with_errors
    command_line = %w{-directory c:/eu -script RunMe -mode wrx }
    args = EnumeratedValidArgs::parse(command_line)
    assert(args.errors?, 
           "An error should have occurred") 
    assert_equal(1,args.errors.validation_errors.length,
                 "There should be 1 problem")
  end
  
end

