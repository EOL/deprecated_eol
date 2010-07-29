require 'optiflag'

# Title: Changing the universal short-form symbol
# Description:  Everything is still the same, except we are now changing the default symbol from '-' to '/'
module Example extend OptiFlagSet(:flag_symbol => "/")
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
## Breaks:
#   ruby example_1_2.rb
#h#   ruby example_1_2.rb -log logdirectory -dir directory -username me -password fluffy  
## Works:
#h#   ruby example_1_2.rb /log logdirectory /dir directory /username me /password fluffy
#   ruby example_1_2.rb --log logdirectory --dir directory --username me --password fluffy
#h#   ruby example_1_2.rb --log logdirectory /dir directory --username me /password fluffy
