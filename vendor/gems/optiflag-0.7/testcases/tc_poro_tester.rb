require 'optiflag.rb'
require 'test/unit'

class Person
  attr_accessor  :name,:ssn
end
class Employee < Person
  attr_accessor  :username,:password
end




class TC_PORO < Test::Unit::TestCase

 
  def test_PORO
    daniel = Employee.new
    cl = " -username doeklund -password AHA -ssn 1234562342 -name DanielEklund"
    ARGV.clear 
    cl.split.each{|x|  ARGV << x}
    OptiFlag.using_object(daniel)
    assert(daniel.username == "doeklund")
    assert(daniel.password == "AHA")
    assert(daniel.ssn == "1234562342")
    assert(daniel.name == "DanielEklund")

  end

end
