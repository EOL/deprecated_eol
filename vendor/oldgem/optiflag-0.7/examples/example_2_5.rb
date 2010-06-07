require 'optiflag'

# Title:  Help flag can be used for a specific flag.
#  Description:  The normal help flag can be used with a parameter so that you can get more information on any of the particular flags.
module Example extend OptiFlagSet
  flag "dir"
  optional_flag "log" do
    description "The directory into which log files will be written"
  end
  flag "username" do 
    description "A Zeta-Blub Appliction Username."
  end
  flag "password" do
    description "Your IT issued password. Don't forget it!"
  end
  usage_flag "h","help","?"

  and_process!
end 

## Normal mode:
#   ruby example_2_5.rb -help 
#   ruby example_2_5.rb -?
#   ruby example_2_5.rb -h
## Help on something specific:
#h#   ruby example_2_5.rb -help username
#h#   ruby example_2_5.rb -? log
#h#   ruby example_2_5.rb -h password
