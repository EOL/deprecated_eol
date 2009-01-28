# any tasks helpful / related to testing

desc 'Truncates all tables'
task :truncate => :environment do
  if RAILS_ENV == 'test'
    require File.join(RAILS_ROOT, 'spec', 'eol_spec_helpers')
    include EOL::Spec::Helpers
    truncate_all_tables :verbose => true
  else
    puts "sorry, i'm not comfortable doing this in any environment but 'test'"
  end
end

desc 'Print specdocs, MATCH=dog_spec,blackbox'
task :specdoc do
  if ENV['MATCH']
    all_specs = Dir[ File.join(RAILS_ROOT, 'spec', '**', '*_spec.rb') ]
    matchers  = ENV['MATCH'].split(',')
    specs = all_specs.inject([]) do |specs, this_spec_filename|
      matchers.each do |matcher|
        if this_spec_filename.include? matcher
          specs << this_spec_filename
          break
        end
      end
      specs
    end
    specs = specs.uniq.join(' ')
  else
    specs = 'spec/*/*_spec.rb'
  end
  cmd = "cd '#{ RAILS_ROOT }' && ruby script/spec --color -f specdoc #{ specs }"
  puts cmd
  exec cmd
end
