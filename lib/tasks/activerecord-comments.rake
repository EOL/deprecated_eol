# need to embed this puppy in the activerecord-comments gem
#
# activerecord-comments needs a way to run these commands given 
# an activerecord connection (so i can pass multiple connections)

#
# TODO this could really use some work!
#

namespace :comments do

  # returns an array of ActiveRecord base classes
  def activerecord_base_classes
    UseDbPlugin.all_use_dbs.map { |klass| klass }
  end

  # TODO use an options Hash instead of all of these params
  def print_comments specific_tables = nil,
                     include_tables_without_comments = false, 
                     include_columns = false, 
                     include_columns_without_comments = false

    puts ""

    require 'activerecord-comments'

    activerecord_base_classes.each do |base|
      
      base.connection.tables.each do |table|

        if specific_tables
          match = false
          specific_tables.each do |matcher|
            match = true if table =~ /#{matcher}/
          end
          next unless match
        end
        
        comment = base.comment(table)
        if comment || include_tables_without_comments
          if comment.length > 40
            puts "[#{table}]\n  #{comment}\n"
          else
            puts "[#{table}]  #{comment}"
          end
        end

        # columns
        if include_columns
          columns_and_comments = { }

          base.connection.columns(table).each do |column|
            column_comment = base.connection.column_comment column.name, table
            if column_comment || include_columns_without_comments
              columns_and_comments[column.name] = column_comment
            end
          end

          unless columns_and_comments.empty?
            longest_comment_name = columns_and_comments.keys.sort_by {|a| a.length }.last
            minimum_spaces       = longest_comment_name.length + 1
            columns_and_comments.each do |name, comment|
              print '  '
              print name
              print ': '
              number_of_spaces = minimum_spaces - name.length
              print (" " * number_of_spaces)
              puts comment
            end
          end

        end # end 'include columns'

        puts "\n" if comment || include_tables_without_comments
      end # end 'each table'
    end # end 'each DB connection'

  end
  
  desc 'Print out [all] table comments, TABLES=users,foo ALL=true (will show tables without comments)'
  task :tables => :environment do
    puts_tables_without_comments = ( ENV['ALL'] == 'true' ) ? true : false
    specific_tables = ( ENV['TABLES'] ) ? ENV['TABLES'].split(',') : nil
    print_comments specific_tables, puts_tables_without_comments, true
  end

end

# default comments task
task :comments do
  Rake::Task['comments:tables'].invoke
end
