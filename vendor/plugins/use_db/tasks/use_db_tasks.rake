# desc "Explaining what the task does"
# task :use_db do
#   # Task goes here
# end

namespace :db do
  namespace :structure do
    task :dump_use_db do            
      require "use_db.rb"
      require "test_model.rb"
      
      UseDbTest.other_databases.each do |options| 
        puts "DUMPING TEST DB: #{options.inspect}" if UseDbPlugin.debug_print
             
        options_dup = options.dup
        options_dup[:rails_env] = "development"    
        conn_spec = UseDbPluginClass.get_use_db_conn_spec(options_dup)
        #establish_connection(conn_spec)

        test_class = UseDbTest.setup_test_model(options[:prefix], options[:suffix], "ForDumpStructure")

        # puts "Dumping DB structure #{test_class.inspect}..."

        case conn_spec["adapter"]
          when "mysql", "oci", "oracle"
            test_class.establish_connection(conn_spec)
            File.open("#{RAILS_ROOT}/db/#{RAILS_ENV}_#{options[:prefix]}_#{options[:suffix]}_structure.sql", "w+") { |f| f << test_class.connection.structure_dump }
=begin      when "postgresql"
            ENV['PGHOST']     = abcs[RAILS_ENV]["host"] if abcs[RAILS_ENV]["host"]
            ENV['PGPORT']     = abcs[RAILS_ENV]["port"].to_s if abcs[RAILS_ENV]["port"]
            ENV['PGPASSWORD'] = abcs[RAILS_ENV]["password"].to_s if abcs[RAILS_ENV]["password"]
            search_path = abcs[RAILS_ENV]["schema_search_path"]
            search_path = "--schema=#{search_path}" if search_path
            `pg_dump -i -U "#{abcs[RAILS_ENV]["username"]}" -s -x -O -f db/#{RAILS_ENV}_structure.sql #{search_path} #{abcs[RAILS_ENV]["database"]}`
            raise "Error dumping database" if $?.exitstatus == 1
          when "sqlite", "sqlite3"
            dbfile = abcs[RAILS_ENV]["database"] || abcs[RAILS_ENV]["dbfile"]
            `#{abcs[RAILS_ENV]["adapter"]} #{dbfile} .schema > db/#{RAILS_ENV}_structure.sql`
          when "sqlserver"
            `scptxfr /s #{abcs[RAILS_ENV]["host"]} /d #{abcs[RAILS_ENV]["database"]} /I /f db\\#{RAILS_ENV}_structure.sql /q /A /r`
            `scptxfr /s #{abcs[RAILS_ENV]["host"]} /d #{abcs[RAILS_ENV]["database"]} /I /F db\ /q /A /r`
          when "firebird"
            set_firebird_env(abcs[RAILS_ENV])
            db_string = firebird_db_string(abcs[RAILS_ENV])
            sh "isql -a #{db_string} > db/#{RAILS_ENV}_structure.sql"
=end        
          else
            raise "Task not supported by '#{conn_spec["adapter"]}'"
        end

        #if test_class.connection.supports_migrations?
        #  File.open("db/#{RAILS_ENV}_structure.sql", "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
        #end

        test_class.connection.disconnect!
      end
    end
  end
  
  namespace :test do
    task :clone_structure => "db:test:clone_structure_use_db"
    
    task :clone_structure_use_db => ["db:structure:dump_use_db","db:test:purge_use_db"] do
      require "use_db.rb"
      require "test_model.rb"
      
      UseDbTest.other_databases.each do |options|   
        
        puts "CLONING TEST DB: #{options.inspect}" if UseDbPlugin.debug_print
           
        options_dup = options.dup
        conn_spec = UseDbPluginClass.get_use_db_conn_spec(options_dup)
        #establish_connection(conn_spec)

        test_class = UseDbTest.setup_test_model(options[:prefix], options[:suffix], "ForClone", "test")

       # puts "Cloning DB structure #{test_class.inspect}..."

        case conn_spec["adapter"]
          when "mysql"
            test_class.connection.execute('SET foreign_key_checks = 0')
            IO.readlines("#{RAILS_ROOT}/db/#{RAILS_ENV}_#{options[:prefix]}_#{options[:suffix]}_structure.sql").join.split("\n\n").each do |table|
              test_class.connection.execute(table)
            end
          when "oci", "oracle"
            IO.readlines("#{RAILS_ROOT}/db/#{RAILS_ENV}_#{options[:prefix]}_#{options[:suffix]}_structure.sql").join.split(";\n\n").each do |ddl|
              test_class.connection.execute(ddl)
            end
=begin      when "postgresql"
            ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
            ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
            ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
            `psql -U "#{abcs["test"]["username"]}" -f db/#{RAILS_ENV}_structure.sql #{abcs["test"]["database"]}`
          when "sqlite", "sqlite3"
            dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
            `#{abcs["test"]["adapter"]} #{dbfile} < db/#{RAILS_ENV}_structure.sql`
          when "sqlserver"
            `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{RAILS_ENV}_structure.sql`
          when "firebird"
            set_firebird_env(abcs["test"])
            db_string = firebird_db_string(abcs["test"])
            sh "isql -i db/#{RAILS_ENV}_structure.sql #{db_string}"
=end
          else
            raise "Task not supported by '#{conn_spec["adapter"]}'"
        end

        test_class.connection.disconnect!
      end
    end
    
    task :purge_use_db => "db:test:purge" do
      require "use_db.rb"
      require "test_model.rb"

      UseDbTest.other_databases.each do |options|
        puts "PURGING TEST DB: #{options.inspect}" if UseDbPlugin.debug_print
        options_dup = options.dup
        options_dup[:rails_env] = "test"
        conn_spec = UseDbPluginClass.get_use_db_conn_spec(options_dup)
        puts "GOT CONN_SPEC: #{conn_spec.inspect}"
        test_class = UseDbTest.setup_test_model(options[:prefix], options[:suffix], "ForPurge", "test")
        puts "GOT TEST_CLASS: #{test_class.inspect}"
        #test_class.establish_connection        

        case conn_spec["adapter"]
          when "mysql"
            test_class.connection.recreate_database(conn_spec["database"])
          when "oci", "oracle"
            test_class.connection.structure_drop.split(";\n\n").each do |ddl|
              test_class.connection.execute(ddl)
            end
          when "firebird"
            test_class.connection.recreate_database!
=begin
          when "postgresql"
            ENV['PGHOST']     = abcs["test"]["host"] if abcs["test"]["host"]
            ENV['PGPORT']     = abcs["test"]["port"].to_s if abcs["test"]["port"]
            ENV['PGPASSWORD'] = abcs["test"]["password"].to_s if abcs["test"]["password"]
            enc_option = "-E #{abcs["test"]["encoding"]}" if abcs["test"]["encoding"]

            ActiveRecord::Base.clear_active_connections!
            `dropdb -U "#{abcs["test"]["username"]}" #{abcs["test"]["database"]}`
            `createdb #{enc_option} -U "#{abcs["test"]["username"]}" #{abcs["test"]["database"]}`
          when "sqlite","sqlite3"
            dbfile = abcs["test"]["database"] || abcs["test"]["dbfile"]
            File.delete(dbfile) if File.exist?(dbfile)
          when "sqlserver"
            dropfkscript = "#{abcs["test"]["host"]}.#{abcs["test"]["database"]}.DP1".gsub(/\\/,'-')
            `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{dropfkscript}`
            `osql -E -S #{abcs["test"]["host"]} -d #{abcs["test"]["database"]} -i db\\#{RAILS_ENV}_structure.sql`
=end
          else
            raise "Task not supported by '#{conn_spec["adapter"]}'"
        end

        test_class.connection.disconnect!    
      end
    end  
  end
end

namespace :test do
  task :units => "db:test:clone_structure_use_db"
  task :functionals => "db:test:clone_structure_use_db"
  task :integrations => "db:test:clone_structure_use_db"
end