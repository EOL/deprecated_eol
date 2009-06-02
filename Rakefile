# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

# add vendor/gems gems to load path
Dir[ File.join(RAILS_ROOT, 'vendor', 'gems', '*', 'lib') ].each do |gem_lib_dir|
  $LOAD_PATH << gem_lib_dir
end

require 'tasks/rails'

require 'scenarios/tasks'
Scenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]
Scenario.before do
  require File.join(RAILS_ROOT, 'spec', 'factories')
end
# Scenario.verbose = true

require 'metric_fu'
MetricFu::Configuration.run do |config|
  #define which metrics you want to use
  config.metrics  = [:churn, :saikuro, :stats, :flog, :flay, :reek, :roodi] #, :rcov]
  config.flay     = { :dirs_to_flay => ['app', 'lib']  } 
  config.flog     = { :dirs_to_flog => ['app', 'lib']  }
  config.reek     = { :dirs_to_reek => ['app', 'lib']  }
  config.roodi    = { :dirs_to_roodi => ['app', 'lib'] }
  config.saikuro  = { :output_directory => 'scratch_directory/saikuro', 
                      :input_directory => ['app', 'lib'],
                      :cyclo => "",
                      :filter_cyclo => "0",
                      :warn_cyclo => "5",
                      :error_cyclo => "7",
                      :formater => "text"} #this needs to be set to "text"
  config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
  config.rcov     = { :test_files => ['spec/**/*_spec.rb'],
                      :rcov_opts => ["--sort coverage", 
                                     "--no-html", 
                                     "--text-coverage",
                                     "--no-color",
                                     "--profile",
                                     "--rails",
                                     "--exclude /gems/,/Library/,spec"]}
end



