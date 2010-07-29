require 'optparse'
require 'simplecli'

class Scenarios::Bin
  include SimpleCLI

  def usage *args
    puts <<doco

  scenarios == %{ Tool For Managing and Loading Ruby Scenarios }

    Usage:
      scenarios command [options]

    Examples:
      scenarios info             # ...

    Further help:
      scenarios commands         # list all available commands
      scenarios help <COMMAND>   # show help for COMMAND
      scenarios help             # show this help message

doco
  end 

  def info_help
    <<doco
Usage: #{ script_name } info

  Summary:
    Display information about the scenarios currently available to you
  end
doco
  end
  def info
    puts Scenarios.info
  end

end
