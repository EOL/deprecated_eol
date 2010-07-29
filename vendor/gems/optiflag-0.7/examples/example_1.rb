require 'optiflag'
# Title: Four required flags (no ordering)
# Description:  The simplest example, where we add four required flags, which have no ordering.
module Example extend OptiFlagSet
  flag "dir"
  flag "log"
  flag "username"
  flag "password"
 
  and_process!
end 

# Some code to _use_ the values
puts "User has input:#{ ARGV.flags.dir  } for dir"
puts "User has input:#{ ARGV.flags.log  } for log"
puts "User has input:#{ ARGV.flags.username  } for username"
puts "User has input:#{ ARGV.flags.password  } for password"

# Try the following inputs
#   ruby example_1.rb
#h#   ruby example_1.rb -log logdirectory -dir directory -username me -password fluffy
