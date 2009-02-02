require 'scenario'
EOL::Scenario.verbose = true

desc 'Print all available scenarios'
task :scenarios do
  if EOL::Scenario.all.empty?
    puts "there are no scenarios.  add some to ./spec/scenarios"
  else
    EOL::Scenario.all.each do |scenario|
      puts "#{ scenario.name }: #{ scenario.description }"
    end  
  end
end

namespace :scenarios do

  desc 'scenarios:load NAME=foo OR NAME=a,b,c'
  task :load => :environment do
    if RAILS_ENV == 'test'
      if ENV['NAME']
        names = ENV['NAME'].split(',')
        EOL::Scenario.load *names
      else
        puts "you need to pass NAME=scenario_name to load a scenario"
      end
    else
      puts "sorry, i'm not comfortable doing this in any environment but 'test'"
    end
  end

  desc 'this will clear the database, load scenarios, & run the site'
  task :run => :environment do
    if RAILS_ENV == 'test'
      if ENV['NAME']

        puts "clearing database ..."
        Rake::Task[:truncate].invoke

        puts "loading scenarios ..."
        names = ENV['NAME'].split(',')
        EOL::Scenario.load *names

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

# a helper until scenarios fully implement old fixtures
desc 'Loads the old fixtures (unless scenarios are complete)'
task :load_old_fixtures do
  ENV['FIXTURES_DIR'] = 'spec_10/fixtures'
  puts "truncating ..."
  Rake::Task[:truncate].invoke
  puts "loading old fixtures ..."
  Rake::Task["spec:db:fixtures:load"].invoke
end
