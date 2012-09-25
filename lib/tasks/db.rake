require Rails.root.join('lib', 'eol_data')

namespace :eol do
  namespace :db do
    desc 'Drop all of the the databases, re-create them, and then bootstrap them.'
    task :rebuild => :environment do
      EOL::DB.rebuild
    end
    desc 'Drop and then create all of the databases associated with your environment.'
    task :recreate => :environment do
      EOL::DB.recreate
    end
    desc 'Create all of the databases associated with your environment.'
    task :create => :environment do
      EOL::DB.create
    end
    desc 'Drop all of the databases associated with your environment.'
    task :drop => :environment do
      EOL::DB.drop
    end
    desc 'Truncate (!) then populate your databases with reasonable testing data.'
    task :populate => :environment do
      EOL::DB.populate
    end
  end
end
