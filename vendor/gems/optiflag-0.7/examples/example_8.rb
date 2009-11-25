require 'optiflag'

# Title: SUPER EASY alternative method for getting command line options into your program.
# Description:  Rather than use the 'module' DSL syntax, we just re-use an existing class.  Any method accessor will be used verbatim as a switch.  OptiFlag will crawl up the inheritance hierarchy up to (but not including) object and use all accessors as standard 'flag's.
class Person
  attr_accessor  :name,:ssn
end
class Employee < Person
  attr_accessor  :username,:password
end

daniel = Employee.new

OptiFlag.using_object(daniel)

puts <<-EOF
     Name: #{ daniel.name}
 Password: #{ daniel.password}
 Username: #{ daniel.username}
      SSN: #{ daniel.ssn}
EOF

#h# ruby example_8.rb 
#h# ruby example_8.rb -username doeklund -password AHA -ssn 1234562342 -name "Daniel Eklund"


