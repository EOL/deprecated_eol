require 'optiflag'

# Title: Using an extended usage flag
#  Description: The extended usage flag allows us to ask for detailed information about our declared flags.
module Example extend OptiFlagSet
  flag "dir"
  optional_flag "log"
  flag "username"
  flag "password"
  usage_flag "h","help","?"
  extended_help_flag "superhelp"

  and_process!
end 

#h#   ruby example_2_1.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_1.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_1.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_1.rb -superhelp --dir directory --username me
#   ruby example_2_1.rb -superhelp --dir directory
#   ruby example_2_1.rb -superhelp 
#h#   ruby example_2_1.rb --superhelp

