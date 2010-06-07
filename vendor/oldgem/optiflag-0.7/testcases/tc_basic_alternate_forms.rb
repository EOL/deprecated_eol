require 'optiflag.rb'
require 'test/unit'

module AlternateArgs extend OptiFlag::Flagset
  flag "directory" do 
    alternate_forms %w{d dir D DIR DIRECTORY}
  end
end



class TC_AlternateArgs < Test::Unit::TestCase

 
  def test_alternate_forms
    command_lines = 
           ["-d FLOTSAM","-dir FLOTSAM",
            "--directory FLOTSAM",
            "-DIR FLOTSAM","-DIRECTORY FLOTSAM",
            "-directory FLOTSAM","-D FLOTSAM"]
    command_lines.each do |command_line|
      args = AlternateArgs::parse(command_line.split)
      assert_equal("FLOTSAM",args.flag_value.directory,
                   "Directory not properly set")
      assert(! args.errors?, 
             "No errors should have occurred")       
    end
  end

end
