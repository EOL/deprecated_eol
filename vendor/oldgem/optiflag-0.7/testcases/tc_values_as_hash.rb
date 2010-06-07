require 'optiflag.rb'
require 'test/unit'

module ValuesAsHashArg extend OptiFlag::Flagset
  flag "&"
  flag "dir"
  flag "star" do
    alternate_forms "*","aster"
  end
  keyword "co"
  usage_flag "h","help","?"

end

class TC_ValuesAsHashArg < Test::Unit::TestCase

  def test_a
    cl = %w{ -dir sdsd co }
    result = ValuesAsHashArg::parse(cl)
    assert(result.flag_value.dir?)
    assert(result.flag_value.dir)
    assert(result.flag_value[:dir])
    assert(result.flag_value[:star] == nil)
  end
  def test_b
    cl = %w{-star STAR -dir sdsd co } 
    result = ValuesAsHashArg::parse(cl) 
    assert(result.flag_value.dir?) 
    assert(result.flag_value.dir == "sdsd")
    assert(result.flag_value[:dir]  == "sdsd")  
    assert(result.flag_value[:star] == "STAR") 
    assert(result.flag_value[:aster] == "STAR") 
    assert(result.flag_value[:*] == "STAR")
  end

  def test_c
    cl = %w{ -dir sdsd co -& amper }
    result = ValuesAsHashArg::parse(cl)
    assert(result.flag_value.dir?)
    assert(! result.flag_value.star?)
    assert(result.flag_value.dir)
    assert(result.flag_value[:dir])
    assert(result.flag_value[:&] == "amper")
  end

end
