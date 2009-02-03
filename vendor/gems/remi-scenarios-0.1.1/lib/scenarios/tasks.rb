# here be rake tasks for scenarios
#
# you can get them in your Rakefile by:
#   require 'scenarios/tasks'
#   Scenario.load_paths = [ 'path/to/my/scenarios/**/*' ]

require 'scenarios'
Scenario.verbose = true

desc 'Print all available scenarios'
task :scenarios do
  if Scenario.all.empty?
    puts "there are no scenarios.  add some to one of the Scenario.load_paths: #{ Scenario.load_paths.inspect }"
  else
    Scenario.all.each do |scenario|
      puts "#{ scenario.name }: #{ scenario.description }"
    end  
  end
end

namespace :scenarios do

  desc 'scenarios:load NAME=foo OR NAME=a,b,c'
  task :load => ( (defined?RAILS_ENV) ? :environment : nil ) do
    if ENV['NAME']
      names = ENV['NAME'].split(',')
      Scenario.load *names
    else
      puts "you need to pass NAME=scenario_name to load a scenario"
    end
  end

end

=begin
  if defined?RAILS_ENV
    # rails-specific task

    desc 'this will clear the database, load scenarios, & run the site'
    task :run => :environment do
      if RAILS_ENV == 'test'
        if ENV['NAME']

          puts "clearing database ..."
          Rake::Task[:truncate].invoke # this isn't defined in scenarios!  need to not call this or include a :truncate task

          puts "loading scenarios ..."
          names = ENV['NAME'].split(',')
          Scenario.load *names

          puts "running the site ..."
          require 'commands/server'

        else
          puts "Usage: rake:run NAME=the_names,of_some,scenarios_to_load RAILS_ENV=test"
        end
      else
        puts "sorry, i'm not comfortable doing this in any environment but 'test'"
      end
    end

  end
=end
