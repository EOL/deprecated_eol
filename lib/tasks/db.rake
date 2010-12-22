require 'eol_data'

namespace :eol do
  namespace :db do
    namespace :create do
      desc 'Create all of the database associated with your environment'
      task :all => :environment do
        include EOL::DB::Create
        all
      end
    end
    namespace :drop do
      desc 'Drop all of the database associated with your environment'
      task :all => :environment do
        include EOL::DB::Drop
        all
      end
    end
  end
end
