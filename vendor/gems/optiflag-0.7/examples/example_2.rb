require 'optiflag'
$log = "c:/log"

# Title:  Adding an optional flag and a usage flag.
# Description: The optional flag allows us to declare that the flag is not required. Even though the help flag comes automatically with 'and_process!' we  can add more synonymns for the default '-h' and '-?'. Also, we show how to use the flag with a ? method.
module Example extend OptiFlagSet
  flag "dir"
  optional_flag "log"
  flag "username"
  flag "password"
  usage_flag "ayudame","help"

  and_process!
end 

if ARGV.flags.log?  # note the question mark '?'
  # this way we know whether or not the flag was
  # set by the user or not
  $log = ARGV.flags.log
  puts "User input: #{ $log } for log via the command-line"
else
  puts "User did NOT input log via the command-line"
end

#h#   ruby example_2.rb --dir directory --username me --password fluffy
#h#   ruby example_2.rb --dir directory --username me --password fluffy --log c:/tmp/log
#   ruby example_2.rb -dir directory -username me -password fluffy -log c:/tmp/log
#h#   ruby example_2.rb -ayudame 
#h#   ruby example_2.rb -?
#   ruby example_2.rb -help

