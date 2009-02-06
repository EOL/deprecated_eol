require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name        = "scenarios"
    s.summary     = "Create, Organize, and Run arbitrary snippets of Ruby code"
    s.email       = "remi@remitaylor.com"
    s.homepage    = "http://github.com/openrain/scenarios"
    s.description = "Create, Organize, and Run arbitrary snippets of Ruby code"
    s.authors     = %w( remi )
    s.files       = FileList["[A-Z]*", "{lib,spec,examples,rails_generators}/**/*"]
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
  rdoc.title    = 'scenarios'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Confirm that gemspec is $SAFE'
task :safe do
  require 'yaml'
  require 'rubygems/specification'
  data = File.read('scenarios.gemspec')
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
