require 'flay'
require 'flog'
require 'roodi'
require 'roodi_task'
## Disabled until we get Ci up to snuff:
#require 'metric_fu'

desc "Analyze for code complexity"
task :flog do

  flog = Flog.new
  flog.flog_files ['app']
  threshold = 291 # We want this to be 40-80, depending on what we allow.

  bad_methods = flog.totals.select {|name, score| score > threshold }
  bad_methods.sort { |a,b| a[1] <=> b[1] }.each do |name, score|
    puts "%8.1f: %s" % [score, name]
  end

  raise "#{bad_methods.size} methods have a flog complexity > #{threshold}" unless bad_methods.empty?

end

desc "Analyze for code duplication"
task :flay do
  threshold = 487 # We would like this to be between 25-60... every codebase is different.
  flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
  flay.process(*Flay.expand_dirs_to_files(['app']))
  flay.report
  raise "#{flay.masses.size} chunks of code have a duplicate mass > #{threshold}" unless flay.masses.empty?
end

RoodiTask.new 'roodi', ['app/**/*.rb', 'lib/**/*.rb'], 'config/roodi.yml'

task :quality => [:flog, :flay, :roodi, 'metrics:all']

