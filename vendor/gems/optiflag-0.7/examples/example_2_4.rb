require 'optiflag'

# Title:  Other clause-level modifiers, like arity and flag symbol  
# Description: Variation 4:  Selectively changing the symbol for a flag, and change the arity to be no-args
module Example extend OptiFlagSet
  flag "dir" do 
    alternate_forms "directory","D","d"
    description "The Appliction Directory"
  end
  optional_flag "log" do
    description "The directory in which to find the log files"
    long_form "logging-directory" 
  end
  flag "username", :description => "Database username."  
  flag "password" do
    description "Database password."
  end
  optional_flag "delete" do
    no_args # stating that this flag accepts no arguments
    description "Delete database when done. Use carefully!!"
    dash_symbol "!" # changing the symbol here
    long_dash_symbol "!!" # changing its long form here
  end
  usage_flag "h","help","?"
  extended_help_flag "superhelp"

  and_process!
end 

if ARGV.flags.delete? 
  # super dangerous code to delete the database....
  puts "Special DELETE flag invoked with special flag-symbol"
end

## Works (uses delete flag with different switch symbol):
#h# ruby example_2_4.rb -d directory -username me -password fluffy !!delete --logging-directory c:/tmp/log
# ruby example_2_4.rb -d directory -username me -password fluffy !delete --logging-directory c:/tmp/log
