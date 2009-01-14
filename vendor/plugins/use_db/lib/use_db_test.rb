require "use_db.rb"
require "test_model.rb"

class UseDbTest

  extend UseDbPlugin

  def self.other_databases
    YAML.load(File.read("#{RAILS_ROOT}/config/use_db.yml")).values.collect(&:symbolize_keys!)
  end

  def self.prepare_test_db(options)
    dump_db_structure(options)
    purge_db(options)
    clone_db_structure(options)
  end
  
  def self.dump_db_structure(options)
    options_dup = options.dup
    options_dup[:rails_env] = "development"    
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)
    
    test_class = setup_test_model(options[:prefix], options[:suffix], "ForDumpStructure")
    
    # puts "Dumping DB structure #{test_class.inspect}..."
          
    case conn_spec["adapter"]
      when "mysql", "oci", "oracle"
        test_class.establish_connection(conn_spec)
        File.open("#{RAILS_ROOT}/db/#{RAILS_ENV}_structure.sql", "w+") { |f| f << test_class.connection.structure_dump }
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
  
  def self.clone_db_structure(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)
    
    test_class = setup_test_model(options[:prefix], options[:suffix], "ForClone")    
    
   # puts "Cloning DB structure #{test_class.inspect}..."
    
    case conn_spec["adapter"]
      when "mysql"
        test_class.connection.execute('SET foreign_key_checks = 0')
        IO.readlines("#{RAILS_ROOT}/db/#{RAILS_ENV}_structure.sql").join.split("\n\n").each do |table|
          test_class.connection.execute(table)
        end
      when "oci", "oracle"
        IO.readlines("#{RAILS_ROOT}/db/#{RAILS_ENV}_structure.sql").join.split(";\n\n").each do |ddl|
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
  
  def self.purge_db(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options_dup)
    #establish_connection(conn_spec)
    
    test_class = setup_test_model(options[:prefix], options[:suffix], "ForPurge")    
    
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

  def self.setup_test_model(prefix="", suffix="", model_suffix="", rails_env=RAILS_ENV)
    prefix ||= ""
    suffix ||= ""
    model_name = "TestModel#{prefix.camelize}#{suffix.camelize}#{model_suffix}".gsub("_","").gsub("-","")
    return eval(model_name) if eval("defined?(#{model_name})")
    create_test_model(model_name, prefix, suffix, rails_env)
    return eval(model_name)
  end
end