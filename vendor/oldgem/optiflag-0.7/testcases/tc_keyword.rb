require 'optiflag.rb'
require 'test/unit'

module KeywordArg extend OptiFlag::Flagset
  flag "dir"
  keyword "checkin" do
    alternate_forms "ci"
  end

  keyword "co"
end

class TC_KeywordArg < Test::Unit::TestCase

  def test_a
    cl = %w{ -dir c:/my_stuff   }
    result = KeywordArg::parse(cl)
    assert(result.flag_value.dir?)
    assert(!result.flag_value.checkin?)
    assert(!result.flag_value.ci?)
  end
  def test_b
    cl = %w{ checkin -dir c:/my_stuff co  }
    result = KeywordArg::parse(cl)
    assert(result.flag_value.dir?)
    assert(result.flag_value.checkin?)
    assert(result.flag_value.co?)
  end
  def test_b
    cl = %w{ checkin -dir c:/my_stuff co  }
    result = KeywordArg::parse(cl)
    assert(result.flag_value.dir?)
    assert(result.flag_value.ci?)
    assert(result.flag_value.co?)
  end
end

