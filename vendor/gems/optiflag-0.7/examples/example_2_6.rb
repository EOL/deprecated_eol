require 'optiflag'

# Title: Using the optional switch flag, a zero argument optional flag
# Description: If your flag is optional and without arguments, it is a switch.  Use optional_switch_flag to indicate.
module Example extend OptiFlagSet
  flag "dir"
  optional_switch_flag "clear"

  and_process!
end 




if ARGV.flags.clear?
  puts "The optional switch flag -clear has been invoked"
else
  puts "The optional switch flag -clear was NOT invoked"
end

#h#   ruby example_2_6.rb -dir c:/dir 
#h#   ruby example_2_6.rb -clear -dir c:/dir 
