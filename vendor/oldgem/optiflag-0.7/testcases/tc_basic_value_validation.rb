require 'optiflag.rb'
require 'test/unit'

module ValidArgs extend OptiFlag::Flagset
  flag "directory"
  flag "script", :description => "The Script directory"
  flag "mode" do 
    value_matches /[0-9]/
  end
  flag ["date"] do
    value_matches ["Must be of form mm\/dd\/yy",  
                   /^[0-9]{2}\/[0-9]{2}\/[0-9]{2,4}$/]
  end

  
end

class TC_ValidArgs < Test::Unit::TestCase

 
  def test_validation
    command_line = %w{-directory c:/eu -script RunMe -mode 3 -date 12/23/2006}
    args = ValidArgs::parse(command_line)
    assert_equal("c:/eu",args.flag_value.directory,
                 "Directory not properly set")
    assert(! args.errors?, 
           "No errors should have occurred") 
  end

  def test_validation_with_errors
    command_line = %w{-directory c:/eu -script RunMe -mode wrx -date monday}
    args = ValidArgs::parse(command_line)
    assert(args.errors?, 
           "An error should have occurred") 
    assert_equal(2,args.errors.validation_errors.length,
                 "There should be 2 problems")
  end
  
end

