class EOL

  # a Scenario is some set of data/logic that can be loaded up easily 
  # to run the application against.
  #
  # if you need to enter abunchof data manually into the EOL website 
  # to test something you're working on, this is a good candidate for
  # a scenario.
  #
  # we can also use scenarios for loading up the base foundation of 
  # data that's required to load the web application
  #
  class Scenario

    attr_accessor :file_path

    def initialize file_path
      @file_path = file_path
    end

    def name
      File.basename(file_path).sub(/\.rb$/, '')
    end

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
      attr_accessor :load_paths

      # returns all Scenarios found using Scenario#load_paths
      def all
        load_paths.inject([]) do |all_scenarios, load_path|
          Dir[ File.join(load_path, '**', '*.rb') ].each do |found_scenario_file|
            all_scenarios << Scenario.new(found_scenario_file)
          end
          all_scenarios
        end
      end

      # returns a scenario by name, eg. EOL::Scenario[:foo]
      #
      # if 1 name is passed in, we'll return that scenario or nil
      #
      # if more than 1 name is passed in, we'll return an array of 
      # scenarios (or an empty array)
      #
      def [] *names
        if names.length == 1
          all.find {|scenario| scenario.name.downcase == names.first.to_s.downcase }
        else
          names.map {|name| self[ name ] }.compact
        end
      end

      # loads a EOL::Scenario, evaluating its code
      #
      # we do this here so we can easily eval in a certain context, 
      # if we want to add a context later
      #
      def load scenario
        eval scenario.source_code # right now, we just eval in this context
      end
    end  

    EOL::Scenario.load_paths ||= [ File.join(RAILS_ROOT, 'spec', 'scenarios') ]

  end
end
