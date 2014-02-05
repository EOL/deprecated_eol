namespace :eol do
  namespace :db do
    desc 'Drop all of the the databases, re-create them, and then bootstrap them.'
    task :rebuild => :environment do
      EOL::Db.rebuild
    end
    desc 'Drop and then create all of the databases associated with your environment.'
    task :recreate => :environment do
      EOL::Db.recreate
    end
    desc 'Create all of the databases associated with your environment.'
    task :create => :environment do
      EOL::Db.create
    end
    desc 'Drop all of the databases associated with your environment.'
    task :drop => :environment do
      EOL::Db.drop
    end
    desc 'Truncate (!) then populate your databases with reasonable testing data.'
    task :populate => :environment do
      EOL::Db.populate
    end
  end
end
