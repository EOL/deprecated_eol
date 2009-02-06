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

  attr_accessor :file_path

  def initialize file_path
    @file_path = file_path
  end

  def name
    File.basename(file_path).sub(/\.rb$/, '')
  end
  alias to_s name

  # if the first line of the scenario's source code 
  # is a comment, we use it as the scenario's description
  #
  # ideally, all scenarios should have a short simple description
  #
  def description
    if first_line =~ /^#/
      first_line.sub(/^#*/, '').strip
    else
      ''
    end
  end

  def first_line
    source_code.split("\n").first
  end

  def source_code
    File.read file_path
  end

  # evaluates the code of the scenario
  def load
    self.class.load self # pass the loading off to the class
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
      puts "looking for scenario(s) with name(s): #{ names.inspect }" if Scenario.verbose
      if names.length == 1
        puts "all scenario names: #{ all.map(&:name) }" if Scenario.verbose
        puts "btw, the load paths are: #{ load_paths.inspect }" if Scenario.verbose
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
      puts "called Scenario.load with scenarios #{ scenarios.inspect }" if Scenario.verbose
      @before_blocks.each { |b| b.call } if @before_blocks and not @before_blocks.empty?
      # TODO should be able to define some block that scenarios get evaluated in!
      #      or some things that scenarios might want to require or ...
      scenarios.each do |scenario|
        scenario = self[scenario] unless scenario.is_a?Scenario # try getting using self[] if not a scenario
        puts "loading #{ scenario.name } (#{ scenario.description })" if Scenario.verbose && scenario.is_a?(Scenario)
        begin
          if scenario.is_a?Scenario
            puts "eval'ing scenario: #{ scenario.inspect }" if Scenario.verbose
            eval scenario.source_code
          else
            puts "Unsure how to load scenario: #{ scenario.inspect }"
          end
        rescue => ex
          raise "An Exception was thrown by scenario: #{ scenario.name }\n\n#{ ex }"
        end
      end
    end
  end  

end
