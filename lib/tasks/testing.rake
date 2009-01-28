# any tasks helpful / related to testing

desc 'Truncates all tables'
task :truncate => :environment do
  if RAILS_ENV == 'test'
    require File.join(RAILS_ROOT, 'spec', 'eol_spec_helpers')
    include EOL::Spec::Helpers
    truncate_all_tables :verbose => true
  else
    puts "hmmm ... are you really sure you want to truncate all tables in an environment besides 'test'?  i'm not gonna let you!"
  end
end

# SCENARIOS

desc 'Print all available scenarios'
task :scenarios do
  require File.join(RAILS_ROOT, 'spec', 'scenario')
  if EOL::Scenario.all.empty?
    puts "there are no scenarios.  add some to ./spec/scenarios"
  else
    EOL::Scenario.all.each do |scenario|
      puts "#{ scenario.name }: #{ scenario.description }"
    end  
  end
end

namespace :scenarios do

  desc 'scenarios:load NAME=foo'
  task :load do
    name = ENV['NAME']
    puts "would load scenario: #{name}"
  end

end
