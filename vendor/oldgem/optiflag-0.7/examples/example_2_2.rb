require 'optiflag'

# Title: Adding 'description' as our first clause-level modifier.
#  Description:  Adding descriptions to the flags so that they will appear in extended help
### NOTE how 'description' can be nested in a block or used as a symbol key
module Example extend OptiFlagSet
  flag "dir" do 
    description "The Appliction Directory"
  end
  optional_flag "log" do
    description "The directory in which to find the log files"
  end
  # alternate form of description can be provided
  # as a hash (to preserve vertical space)
  flag "username", :description => "Database username."  
  flag "password" do
    description "Database password."
  end
  usage_flag "h","help","?"
  extended_help_flag "superhelp"

  and_process!
end 

## Works (triggers extended help):
#   ruby example_2_2.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_2.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_2.rb -superhelp --dir directory --username me --password fluffy
#   ruby example_2_2.rb -superhelp --dir directory --username me
#   ruby example_2_2.rb -superhelp --dir directory
#   ruby example_2_2.rb -superhelp 
#h#   ruby example_2_2.rb --superhelp

