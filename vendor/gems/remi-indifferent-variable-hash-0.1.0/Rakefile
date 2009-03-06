require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'spec/rake/spectask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name        = "indifferent-variable-hash"
    s.summary     = "easily add hash-like features to any class / instance"
    s.email       = "remi@remitaylor.com"
    s.homepage    = "http://github.com/remi/indifferent-variable-hash"
    s.description = "easily add hash-like features to any class / instance"
    s.authors     = %w( remi )
    s.files       = FileList["[A-Z]*", "{lib,spec,examples,rails_generators}/**/*"] 
    # s.executables = "foo" 
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
  rdoc.title    = 'indifferent-variable-hash'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('RDOC_README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Confirm that gemspec is $SAFE'
task :safe do
  require 'yaml'
  require 'rubygems/specification'
  data = File.read('indifferent-variable-hash.gemspec')
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
