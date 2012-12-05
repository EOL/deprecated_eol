# here be rake tasks for scenarios
#
# you can get them in your Rakefile by:
#   require 'eol_scenarios/tasks'
#   EolScenario.load_paths = [ 'path/to/my/scenarios/**/*' ]

require 'eol_scenarios'

desc 'Print all available scenarios'
task :scenarios do
  if EolScenario.all.empty?
    puts "there are no scenarios.  add some to one of the EolScenario.load_paths: #{ EolScenario.load_paths.inspect }"
  else
    EolScenario.all.each do |scenario|
      puts "#{ scenario.name }: #{ scenario.summary }"
    end  
  end
end

namespace :scenarios do

  desc 'scenarios:load NAME=foo OR NAME=a,b,c'
  task :load => :environment do
    puts "called scenarios:load" if EolScenario.verbose
    if ENV['NAME']
      names = ENV['NAME'].split(',')
      EolScenario.load *names
    else
      puts "you need to pass NAME=scenario_name to load a scenario"
    end
  end

  desc 'scenarios:show NAME=foo OR NAME=a,b,c'
  task :show do
    if ENV['NAME']
      names = ENV['NAME'].split(',')
      names.each do |scenario_name|
        if scenario = EolScenario[scenario_name]
          puts scenario.info
          puts ('-' * 40)
        else
          puts "Scenario not found: #{ scenario_name }"
        end
      end
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
          EolScenario.load *names

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
