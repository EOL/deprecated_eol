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
