# need to embed this puppy in the activerecord-comments gem
#
# activerecord-comments needs a way to run these commands given 
# an activerecord connection (so i can pass multiple connections)

namespace :comments do

  # returns an array of ActiveRecord base classes
  def activerecord_base_classes
    UseDbPlugin.all_use_dbs.map { |klass| klass }
  end
  
  desc 'Print out all table comments, ALL=true (will show tables without comments)'
  task :tables => :environment do
    require 'activerecord-comments'

    puts_tables_without_comments = ( ENV['ALL'] == 'true' ) ? true : false

    activerecord_base_classes.each do |base|
      base.connection.tables.each        do |table|
        comment = base.comment(table)
        puts "#{table}:  #{comment}" if comment || puts_tables_without_comments
      end
    end
  end

end

# default comments task
task :comments do
  Rake::Task['comments:tables'].invoke
end
