#
# Stupidly simple way to get a CLI that handles:
#     myapp somecommand --blah=5 args --more stuff -y
#
# All it does is, if the "command" (or "action") passed 
# has a method with the same name, the rest of the args 
# are passed to the method.
#
# If you provide a command_help method that returns help 
# info as a String, that'll be used when you call:
#     myapp help somecommand
#
# If you provide a 'Summary:\n blah blah blah' bit in 
# your help_somecommand, it'll be used as the command's 
# summary and your command will show up when you:
#     myapp commands
#
# To use, include in your class
#
# NOTE: if you use the 'default' command functionality, 
# we don'e even bother to check to see if we respond_to? 
# what you provide as a default command, incase it 
# uses method missing or something.  So it's *YOUR* 
# responsibility to provide this method
#
# Conventionally, your 'default' method should simple pass
# along the arguments to another defined and documented command!
#
module SimpleCLI
  attr_accessor :options
  attr_reader   :args, :command, :command_args

  def initialize args = [], options = {}
    @args     = args
    @options  = options
    parse!
  end

  # figure out what command to run, arguments to pass it, etc
  #
  # call #run afterwards, to run.  or call parse! to parse and run
  #
  # typically, you shouldn't call this yourself.  call parse when you 
  # want to RE-parse the arguments passed in, because initialize auto-parses
  #
  # typical:
  #     Bin.new( ARGV ).run
  #     Bin.new( ARGV, :default => 'some_default_method ).run
  #
  # use this is you want to ...
  #     bin = Bin.new ARGV
  #     bin.options[:default] = 'some_default_method'
  #     bin.instance_eval { 'do some custom stuff that might change the command to run, etc' }
  #     bin.parse!
  #     bin.run
  #
  def parse!
    args = @args.clone

    @default_command  = @options[:default].to_s if @options.keys.include? :default
    @commands         = all_commands
    
    if not args.empty? and @commands.map{|c|c.downcase}.include? args.first.downcase
      @command = args.shift.downcase
    else
      @command = (args.empty?) ? 'usage' : ( @default_command || 'usage' )
    end
    
    @command_args     = args
  end
  
  # run command determined by parse
  def run
    begin
      self.send @command, *@command_args
    rescue ArgumentError => ex
      puts "'#{@command}' called with wrong number of arguments\n\n"
      puts help_for( @command )
    end
  end

  # returns names of all defined 'command' methods
  #
  # only returns methods with methodname_help sister methods, 
  # inotherwords: only returns DOCUMENTED methods 
  # ... this should get you to document that command!
  def all_commands
    self.methods.sort.grep( /_help/ ).collect{ |help_method| help_method.gsub( /(.*)_help/ , '\1' ) }
  end

  # returns help String for command
  def help_for command
    help_method = "#{ command }_help".to_sym
    self.send( help_method ) if self.respond_to? help_method
  end

  # returns summary String for command (extracted from help_for command)
  #
  # Looks for
  #     Summary:
  #        some summary text here, on a new line after 'Summary:'
  #
  def summary_for command
    doco = help_for command
    if doco
      match = /Summary:\n*(.*)/.match doco
      if match and match.length > 1
        match[1].strip
      end
    end
  end

  # default usage message, called if we can't figure out what command to run
  #
  # override in your app by re-defining - it should puts the message (or do whatever) itself!
  # this method doesn't return a string, like blah_help methods (which are called by #help).
  # usage is called, all by itself ... so it needs to print itself!
  #
  def usage *args
    puts "default usage message.  please define a 'usage' method returning a new message."
  end

  # shortcut to pretty file name of script, which can be used in your help doco
  def script_name
    File.basename $0
  end

  # HELP
  def help_help
    <<doco
Usage: #{ script_name } help COMMAND

  Summary:
    Provide help documentation for a command
doco
  end
  def help *args
    command = args.shift
    if command.nil?
      puts help_for( :help )
    elsif (doco = help_for command)
      puts doco
    else
      puts "No documentation found for command: #{command}"
    end
  end

  # COMMANDS
  def commands_help
    <<doco
Usage: #{ script_name } commands

  Summary:
    List all '#{ script_name }' commands
doco
  end
  def commands *no_args
    before_spaces = 4
    after_spaces  = 18
    text = all_commands.inject(''){ |all,cmd| all << "\n#{' ' * before_spaces}#{cmd}#{' ' * (after_spaces - cmd.length)}#{summary_for(cmd)}" }
    puts <<doco 
#{ script_name } commands are:

    DEFAULT COMMAND   #{ @default_command || 'not set' }
#{ text }

For help on a particular command, use '#{ script_name } help COMMAND'.
doco

#If you've made a command and it's not showing up here, you
#need to make help method named 'COMMAND_help' that returns 
#your commands help documentation.
#
#[NOT YET IMPLEMENTED:]
#Commands may be abbreviated, so long as they are unumbiguous.
#e.g. 'snip h commands' is short for 'snip help commands'.
#doco
  end

end
