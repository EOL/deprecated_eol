# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
begin
  # let's try the hanna template, if it's installed
  #   $ sudo gem install mislav-hanna
  # see: http://github.com/mislav/hanna
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask' # default to normal RDoc template
end

require 'tasks/rails'

# add vendor/gems gems to load path
Dir[ File.join(RAILS_ROOT, 'vendor', 'gems', '*', 'lib') ].each do |gem_lib_dir|
  $LOAD_PATH << gem_lib_dir
end

require 'scenarios/tasks'
Scenario.load_paths <<  File.join(RAILS_ROOT, 'spec', 'scenarios')
Scenario.before do
  require File.join(RAILS_ROOT, 'spec', 'spec_helper')
end
