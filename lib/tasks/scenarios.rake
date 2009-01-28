require 'scenario'

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
        puts "you need to pass NAME=scenario_name to load a scenario" unless ENV['NAME']
      end
    else
      puts "sorry, i'm not comfortable doing this in any environment but 'test'"
    end
  end

end
