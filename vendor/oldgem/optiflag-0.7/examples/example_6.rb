require 'optiflag'

# Title:  Accessing values of the flags through a hash instead of a method.
# Description:  Usually we have been accessing by doing this 'ARGV.flags.dir' but if you have a flag with a non alpha-numeric flag can't be accessed via a method name.  Therefore we have to use a hash.
module HashAcess extend OptiFlagSet
  flag "dir"
  flag "log_level"
  flag "and"
  
  and_process!
end 

puts "Dir is: #{ ARGV.flags[:dir] }"
puts "Log Level is: #{ ARGV.flags[:log_level] }"
puts "And Level is: #{ ARGV.flags[:and] }"

#h# ruby example_6.rb -dir "c:/Program Files/Apache Software Foundation/Tomcat 5/" -log_level 3 -and ETALL



