# Top-level namespace for Scenarios
#
# Holds configuration for Scenarios 
# and acts as a bit of a utility class, 
# holding lots of methods / logic
# used by Scenarios.
#
class Scenarios
  class << self

    # include IndifferentVariableHash in Scenarios so we can 
    # get/set easily configuration settings for Scenarios
    include IndifferentVariableHash

    # alias config to variables attribute provided by 
    # IndifferentVariableHash so we can say:
    #   
    #   # these all return the value of configuration 
    #   # setting 'foo'
    #   Scenarios.config.foo
    #   Scenarios.config[:foo]
    #   Scenarios[:foo]
    #   Scenarios.foo
    #
    alias config variables

    # returns a formatted string displaying 
    # information about the current Scenarios 
    # environment and conifuguration, etc etc.
    def info
      "hello from Scenarios#info"
    end
  end
end
