require 'optiflag.rb'
require 'test/unit'

module SymbolArgs extend OptiFlag::Flagset(:flag_symbol => "/")
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
module AnotherSymbolArgs extend OptiFlag::Flagset
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

class TC_SymbolArgs < Test::Unit::TestCase

 
  def test_validation
    command_line = %w{/directory c:/eu /script RunMe /mode 3 /date 12/23/2006}
    args = SymbolArgs::parse(command_line)
    assert(! args.errors?, 
           "No errors should have occurred") 
    assert_equal("c:/eu",args.flag_value.directory,
                 "Directory not properly set")

    args2 = AnotherSymbolArgs::parse(command_line)
    assert(args2.errors?, 
           "An error should have occurred") 
    assert_equal(4,args2.errors.missing_flags.length,
                 "There should be 4 problems")    
  end

  def test_validation_with_errors
    command_line = %w{-directory c:/eu -script RunMe -mode 3 -date 12/23/2006}
    args = SymbolArgs::parse(command_line)
    assert(args.errors?, 
           "An error should have occurred") 
    assert_equal(4,args.errors.missing_flags.length,
                 "There should be 4 problems")
    args2 = AnotherSymbolArgs::parse(command_line)
    assert_equal("c:/eu",args2.flag_value.directory,
                 "Directory not properly set")
    assert(! args2.errors?, 
           "No errors should have occurred") 
    
  end
  
end

