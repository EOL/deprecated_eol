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

# We have some pretty customized stat directories, so:
require 'spec/rake/spectask'
namespace :spec do
  # Setup specs for stats
  task :statsetup do
    require 'code_statistics'
    ::STATS_DIRECTORIES << %w(Blackbox\ specs spec/blackbox) if File.exist?('spec/blackbox')
    ::STATS_DIRECTORIES << %w(Model\ specs spec/models) if File.exist?('spec/models')
    ::STATS_DIRECTORIES << %w(View\ specs spec/views) if File.exist?('spec/views')
    ::STATS_DIRECTORIES << %w(Controller\ specs spec/controllers) if File.exist?('spec/controllers')
    ::STATS_DIRECTORIES << %w(Selenium\ specs spec/selenium) if File.exist?('spec/selenium')
    ::STATS_DIRECTORIES << %w(Helper\ specs spec/helpers) if File.exist?('spec/helpers')
    ::STATS_DIRECTORIES << %w(Library\ specs spec/lib) if File.exist?('spec/lib')
    ::STATS_DIRECTORIES << %w(Cucumber\ features features) if File.exist?('features')
    ::CodeStatistics::TEST_TYPES << "Model specs" if File.exist?('spec/models')
    ::CodeStatistics::TEST_TYPES << "View specs" if File.exist?('spec/views')
    ::CodeStatistics::TEST_TYPES << "Blackbox specs" if File.exist?('spec/blackbox')
    ::CodeStatistics::TEST_TYPES << "Selenium specs" if File.exist?('spec/selenium')
    ::CodeStatistics::TEST_TYPES << "Controller specs" if File.exist?('spec/controllers')
    ::CodeStatistics::TEST_TYPES << "Helper specs" if File.exist?('spec/helpers')
    ::CodeStatistics::TEST_TYPES << "Library specs" if File.exist?('spec/lib')
    ::CodeStatistics::TEST_TYPES << "Cucumber features" if File.exist?('features')
    ::STATS_DIRECTORIES.delete_if {|a| a[0] =~ /test/}
  end
end
