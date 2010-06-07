# a Scenario is some set of data/logic that can be loaded up easily 
# to run an application against.
#
# if you need to enter abunchof data manually into the a website 
# to test something you're working on, this is a good candidate for
# a scenario.
#
# we can also use scenarios for loading up the base foundation of 
# data that's required to load the web application
#
# TODO define what is public/private and document public API in README and
#      actually give private methods a private visibility
#
class Scenario
  include IndifferentVariableHash

  attr_accessor :file_path

  def initialize file_path
    @file_path = file_path
    source_code # does some parsing ... eager load this!  otherwise Scenario[:first].some_var won't work
  end

  def name
    File.basename(file_path).sub(/\.rb$/, '')
  end
  alias to_s name

  # returns a formatted string, showing information 
  # about this current scenario
  def info
    str = <<INFO
Scenario: #{ name }
Summary: #{ summary }
Description: #{ description_without_summary }
INFO
    variables.each do |key, value|
      str << "#{ key }: #{ value.inspect }\n"
    end
    str
  end

  # if the first line of the scenario's source code 
  # is a comment, we use it as the scenario's summary
  #
  # ideally, all scenarios should have a short simple summary
  #
  def summary
    if first_line =~ /^#/
      first_line.sub(/^#*/, '').strip
    else
      ''
    end
  end

  def first_line
    header.split("\n").first #.gsub(/^#* ?/, '')
  end

  def source_code
    unless @source_code
      # the first time we read in the source code, 
      # see if there are any variables in the header 
      # and, if so, set them via IndifferentVariableHash
      @source_code = File.read file_path
      yaml_frontmatter = header.gsub(/^#* ?/, '')[/^---.*/m]
      if yaml_frontmatter
        require 'yaml'
        header_variables = YAML::load(yaml_frontmatter)
        variables.merge!(header_variables) if header_variables
      end
    end
    @source_code
  end

  def description
    header.gsub(/^#* ?/, '').gsub(/^---.*/m, '').strip # gets rid of comment hashes and yaml
  end

  def description_without_summary
    parts = description.split("\n")
    parts.shift
    parts.join("\n")
  end

  # evaluates the code of the scenario
  def load
    self.class.load self # pass the loading off to the class
  end

  # Comment header, any comments at the top of the source code
  def header
    source_code.gsub /\n^[^#].*/m, ''
  end

  class << self

    # an array of the paths where scenarios can be found
    #
    # any .rb file found in these directories is assumed to 
    # be a scenario
    #
    attr_accessor :load_paths, :verbose, :before_blocks

    # returns all Scenarios found using Scenario#load_paths
    def all
      load_paths.inject([]) do |all_scenarios, load_path|
        Dir[ File.join(load_path, '**', '*.rb') ].each do |found_scenario_file|
          all_scenarios << Scenario.new(found_scenario_file)
        end
        all_scenarios
      end
    end

    def verbose= value
      if value == true && @verbose != true
        puts "Scenario verbose enable."
        puts "Scenario load_paths => #{ Scenario.load_paths.inspect }"
        puts "#{ Scenario.all.length } scenario(s) found"
      end
      @verbose = value
    end

    # run some block of code before any scenarios run
    #
    # good for last-minute require statements and whatnot
    #
    def before &block
      @before_blocks ||= []
      @before_blocks << block if block
    end

    # returns a scenario by name, eg. Scenario[:foo]
    #
    # if 1 name is passed in, we'll return that scenario or nil
    #
    # if more than 1 name is passed in, we'll return an array of 
    # scenarios (or an empty array)
    #
    def [] *names
      # puts "Scenario#{ names.inspect }" if Scenario.verbose
      if names.length == 1
        all.find {|scenario| scenario.name.downcase == names.first.to_s.downcase }
      else
        names.map {|name| self[ name ] }.compact
      end
    end

    # loads a Scenario, evaluating its code
    #
    # we do this here so we can easily eval in a certain context, 
    # if we want to add a context later
    #
    #   Scenario.load @scenario1, @scenario2
    #   Scenario.load :names, 'work', :too
    #
    def load *scenarios
    puts "Scenario.load(#{ scenarios.map {|s| s.to_s }.join(', ') })" if Scenario.verbose
      @before_blocks.each { |b| b.call } if @before_blocks and not @before_blocks.empty?
      
      # TODO should be able to define some block that scenarios get evaluated in!
      #      or some things that scenarios might want to require or ...

      options = ( scenarios.last.is_a?(Hash) ) ? scenarios.pop : { }
      options[:unique] ||= true # whether each scenario passed has to be unique ... will likely change this to be true by default
      options[:whiny] = true if options[:whiny].nil?

      # make sure everything is actually a Scenario object
      #
      # after this, we can safely assume that everything is a scenario!
      #
      scenarios.map! do |scenario|
        scenario.is_a?(Scenario) ? scenario : self[scenario]
      end
      scenarios.compact!

      scenarios = scenarios.inject([]) do |all, scenario|
        all += Scenario[ nil, *scenario.dependencies ] if scenario.dependencies
        all << scenario
        all
      end
      scenarios.compact!

      puts "[ after dependencies, scenarios => #{ scenarios.map {|s| s.to_s }.join(', ') } ]" if Scenario.verbose

      scenarios = scenarios.inject([]) do |all, scenario|
        existing_scenario = all.find {|s| s.name == scenario.name }
        if existing_scenario
          # the last scenario with the given name "wins" (but we need to persist order)
          index_of_existing_scenario = all.index existing_scenario
          all.delete_at index_of_existing_scenario
          all.insert index_of_existing_scenario, scenario
        else
          all << scenario
        end
        all
      end if options[:unique]

      puts "scenarios to load: #{ scenarios.map {|s| s.to_s }.join(', ') }" if Scenario.verbose
      scenarios.each do |scenario|
        scenario = self[scenario] unless scenario.is_a?Scenario # try getting using self[] if not a scenario
        puts "... loading #{ scenario.name } (#{ scenario.summary })" if Scenario.verbose
        begin
          if scenario.is_a?Scenario
            puts "loading scenario: #{ scenario.file_path }" if Scenario.verbose

            # TODO update to eval ... should load in a custom context ...
            #      the eval should also catch exceptions and print the 
            #      line number that threw the exception, etc etc
            Kernel::load scenario.file_path
          else
            puts "Unsure how to load scenario: #{ scenario.inspect }" if options[:whiny]
          end
        rescue => ex
          puts "An Exception was thrown by scenario: #{ scenario.name }" if options[:whiny]
          raise ex
        end
      end
    end
  end  

end
