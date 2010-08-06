require 'optiflag.rb'
require 'test/unit'


module CharArgs extend OptiFlag::Flagset
  character_flag :l, :p_group
  character_flag :s, :p_group
  character_flag :a, :p_group
  optional_switch_flag "clear"
  character_flag :x do
    description "Extract"
  end
  character_flag :v
  character_flag :f
  flag "dir"
  keyword "bobby"
end

class TC_CharArgs < Test::Unit::TestCase

  def test_xvf
    command_lines = ["-x bobby -v -f -dir sdsdsd",
                     "-xvf", 
                     "-vxf",
                     "-fvx bobby",
                     "-f -dir kosd -xv",
                     "-dir sdsd -x -fv",
                     "-x -vf",
                     "-f -vx",
                     "-v -f -x -vo sd"]
    command_lines.each do |x|
      argv = x.split
      args = CharArgs::parse(argv)
      assert_equal(true,args.flags.f?,
                   "The 'f' flag should be set")
      assert_equal(true,args.flags.v?,
                   "The 'v' flag should be set")
      assert_equal(true,args.flags.x?,
                   "The 'x' flag should be set")

    end
  end

  def test_lsa
    command_lines = ["-x bobby -v -f -dir sdsdsd",
                     "-xvf", 
                     "-vxf",
                     "-fvx bobby",
                     "-f -dir kosd -xv",
                     "-dir sdsd -x -fv",
                     "-x -vf",
                     "-f -vx",
                     "-v -f -x -vo sd"]
    command_lines.each do |x|
      argv = x.split
      args = CharArgs::parse(argv)
      assert_equal(false,args.flags.l?)
      assert_equal(false,args.flags.s?)
      assert_equal(false,args.flags.a?)
      end
  end
  def test_lsa_not_there
    command_lines = ["-lsa",
                     "-las",
                     "-als",
                     "-asl",
                     "-sal",
                     "-sla",
                     "-s -la",
                     "-s -al",
                     "-a -sl",
                     "-a -ls ",
                     "-l -s -a",
                     "--l --s --a",
                     "-lsa bobby -dir sdsd",
                     "bobby -dir sdsd -las",
                     "-als bobby -dir sdsd",
                     "bobby -asl",
                     "-sal -dir sdsd",
                     "-sla",
                     "-s bobby -la",
                     "-s -al",
                     "-a bobby -sl",
                     "-a -ls",
                     "-l bobby -dir sdsd -s -a"]

    command_lines.each do |x|
      argv = x.split
      args = CharArgs::parse(argv)
      assert_equal(true,args.flags.l?)
      assert_equal(true,args.flags.s?)
      assert_equal(true,args.flags.a?)
      assert_equal(false,args.flags.x?)
      assert_equal(false,args.flags.v?)
      assert_equal(false,args.flags.f?)
      end
  end



  
end

