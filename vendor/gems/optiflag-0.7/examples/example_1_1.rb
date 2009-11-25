require 'optiflag'
# Title: Four required flags (no ordering), accessing via the module name.
# Description:  Exact same as the previous, except we show that the module name may be used to access the flag values, if you don't want to get them from ARGV. (It's a style thing)
module Example extend OptiFlagSet
  flag "dir"
  flag "log"
  flag "username"
  flag "password"
 
  and_process!
end 

# Some code to _use_ the values
puts "User has input:#{ Example.flags.dir  } for dir"
puts "User has input:#{ Example.flags.log  } for log"
puts "User has input:#{ Example.flags.username  } for username"
puts "User has input:#{ Example.flags.password  } for password"

# Try the following inputs
#   ruby example_1.rb
#h#   ruby example_1.rb -log logdirectory -dir directory -username me -password fluffy
