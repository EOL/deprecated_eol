require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name        = "rackbox"
    s.summary     = "Merb-like BlackBox testing for Rack apps, including Rails"
    s.email       = "remi@remitaylor.com"
    s.homepage    = "http://github.com/remi/rackbox"
    s.description = "Merb-like BlackBox testing for Rack apps, including Rails"
    s.authors     = %w( remi )
    s.files       = FileList["[A-Z]*", "{lib,spec,examples,rails_generators}/**/*"] 
    # s.executables = "neato" 
    # s.add_dependency 'person-project' 
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'rackbox'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('RDOC_README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Confirm that gemspec is $SAFE'
task :safe do
  require 'yaml'
  require 'rubygems/specification'
  data = File.read('rackbox.gemspec')
  spec = nil
  if data !~ %r{!ruby/object:Gem::Specification}
    Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
  else
    spec = YAML.load(data)
  end
  spec.validate
  puts spec
  puts "OK"
end

task :default => :spec
