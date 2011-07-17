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

require 'eol_scenarios/tasks'
EolScenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]
EolScenario.before do
  require File.join(RAILS_ROOT, 'spec', 'factories')
end
# EolScenario.verbose = true

# We have some pretty customized stat directories, so:
require 'spec/rake/spectask'
namespace :spec do
  # Setup specs for stats
  task :statsetup do
    require 'code_statistics'
    ::STATS_DIRECTORIES << %w(Integration\ specs spec/integration) if File.exist?('spec/integration')
    ::STATS_DIRECTORIES << %w(Model\ specs spec/models) if File.exist?('spec/models')
    ::STATS_DIRECTORIES << %w(View\ specs spec/views) if File.exist?('spec/views')
    ::STATS_DIRECTORIES << %w(Controller\ specs spec/controllers) if File.exist?('spec/controllers')
    ::STATS_DIRECTORIES << %w(Helper\ specs spec/helpers) if File.exist?('spec/helpers')
    ::STATS_DIRECTORIES << %w(Library\ specs spec/lib) if File.exist?('spec/lib')
    ::STATS_DIRECTORIES << %w(Cucumber\ features features) if File.exist?('features')
    ::CodeStatistics::TEST_TYPES << "Model specs" if File.exist?('spec/models')
    ::CodeStatistics::TEST_TYPES << "View specs" if File.exist?('spec/views')
    ::CodeStatistics::TEST_TYPES << "Integration specs" if File.exist?('spec/integration')
    ::CodeStatistics::TEST_TYPES << "Selenium specs" if File.exist?('spec/selenium')
    ::CodeStatistics::TEST_TYPES << "Controller specs" if File.exist?('spec/controllers')
    ::CodeStatistics::TEST_TYPES << "Helper specs" if File.exist?('spec/helpers')
    ::CodeStatistics::TEST_TYPES << "Library specs" if File.exist?('spec/lib')
    ::CodeStatistics::TEST_TYPES << "Cucumber features" if File.exist?('features')
    ::STATS_DIRECTORIES.delete_if {|a| a[0] =~ /test/}
  end
end

# begin
#   require 'metric_fu'
# rescue LoadError
#   puts "++ You may want to 'gem install metric_fu' for additional metric functionality."
# end
# 
# if defined?(MetricFu)
#   MetricFu::Configuration.run do |config|
#     # Flog is not working.  At all.  Seems like it was using the wrong version of something, but...
#     config.metrics = [:churn, :flay, :reek, :roodi, :hotspots, :saikuro, :stats]
#     config.graphs  = [:flay, :reek, :roodi, :rails_best_practices]
#     config.rcov[:test_files] = ['spec/**/*_spec.rb']
#     config.rcov[:rcov_opts] << "-Ispec" # Needed to find spec_helper
#   end
# end
