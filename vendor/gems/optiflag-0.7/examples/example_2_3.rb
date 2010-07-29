require 'optiflag'

#  Title:  Adding alternate forms and long forms
#  Description: Alternate forms may be used in place of the regular flag.  Long forms are used with the long form dispatch symbol (usually '--')
module Example extend OptiFlagSet
  flag "dir" do 
    alternate_forms "directory","D","d"
    description "The Appliction Directory"
  end
  optional_flag "log" do
    description "The directory in which to find the log files"
    long_form "logging-directory" # long form is keyed after the '--' symbol
  end
  flag "username", :description => "Database username."  # alternate form
  flag "password" do
    description "Database password."
  end
  usage_flag "h","help","?"
  extended_help_flag "superhelp"

  and_process!
end 

# Some code to _use_ the values
puts "User has input: #{ ARGV.flags.dir  } for dir"
puts "User has input: #{ ARGV.flags.username  } for username"
puts "User has input: #{ ARGV.flags.password  } for password"
if ARGV.flags.log?
  puts "User has input: #{ARGV.flags.log  } for log"
end

# Try the following inputs
#h#   ruby example_2_3.rb -dir directory -username me -password fluffy
#   ruby example_2_3.rb -D directory -username me -password fluffy
#h#   ruby example_2_3.rb -d directory -username me -password fluffy
## Works (uses different long form for log):
#h#  ruby example_2_3.rb -d directory -username me -password fluffy --logging-directory c:/tmp/log
