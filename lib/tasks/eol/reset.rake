namespace :eol do
  desc 'Attempts to "reset" the database to a clean state; tests more likely ' \
    'to pass.'
  task :reset => :environment do
    EOL::Db.reset
  end
end
