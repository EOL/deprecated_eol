require 'optiflag.rb'
require 'test/unit'

module BUG_ONE extend OptiFlag::Flagset
  flag "dir" do
    alternate_forms "D","d"
  end
  flag "log"
  flag "db", :description => "The database"
  optional_flag "verbose"
end



class TC_BUG_ONE < Test::Unit::TestCase
 
  def test_bug
    command_line = "-log LOG -dir LOG  -db DB"
    args = BUG_ONE::parse(command_line.split)
    assert(! args.errors?, 
           "No errors should have occurred")       

  end

end
