require 'optiflag'

# Title:  Adding validation rules to the value of an input flag
# Description: See the flags  "mode", "run_date", and "connection" for examples of both forcing values to be in a set (value_in_set) or to match a particular regexp (value_matches).
module Example extend OptiFlagSet
  flag "dir" 
  flag "connection" do
    # this is our new clause-level modifier
    value_matches ["Connection string must be of the form username/password@servicename", 
                   /^\b.+\b\/\b.+@.+$/ ]
  end
  optional_flag "mode" do
    # this is our second new clause-level modifier
    value_in_set ["read","write","execute"]
  end
  optional_flag "run_date" do
    value_matches ["run_date must be of the form mm/DD/YY",
                   /^[0-9]{2}\/[0-9]{2}\/[0-9]{2,4}$/]
  end

  and_process! 
end 

flag = Example.flags

puts "Mode flag is #{ flag.mode }" if flag.mode?
puts "Run Date flag is #{ flag.run_date }" if flag.run_date?
puts "Connection flag is #{ flag.connection }" if flag.connection?


# Try the following inputs
#h# ruby example_3.rb -dir directory -connection deklund/password@HAL.FBI.GOV -mode read -run_date 12/23/2005
## Breaks (breaks a validation rule)
#h# ruby example_3.rb -dir directory -connection 78GCTHR.com
#h# ruby example_3.rb -dir directory -connection deklund/password@HAL.FBI.GOV -mode CRACK! -run_date 12/23/2005

