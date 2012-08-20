# Top-level namespace for EolScenarios
#
# Holds configuration for EolScenarios 
# and acts as a bit of a utility class, 
# holding lots of methods / logic
# used by EolScenarios.
#
class EolScenarios
  class << self

    # include IndifferentVariableHash in EolScenarios so we can 
    # get/set easily configuration settings for EolScenarios
    include IndifferentVariableHash

    # alias config to variables attribute provided by 
    # IndifferentVariableHash so we can say:
    #   
    #   # these all return the value of configuration 
    #   # setting 'foo'
    #   EolScenarios.config.foo
    #   EolScenarios.config[:foo]
    #   EolScenarios[:foo]
    #   EolScenarios.foo
    #
    alias config variables

    # returns a formatted string displaying 
    # information about the current EolScenarios 
    # environment and conifuguration, etc etc.
    def info
      "hello from EolScenarios#info"
    end
  end
end
