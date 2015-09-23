require_relative '../../spec/spec_helper' if Rails.env == 'test'
module EOL
  class ScenarioLoader

    attr_reader :name

    # NOTE that this truncates before each, to create IDs starting from 1.
    def self.load_all_with_caching
      Dir[Rails.root.join("scenarios", "*.rb")].each do |file|
        scenario_name = file.split("/").last.sub(/\.rb$/, '')
        next if scenario_name == "raises_exception" # :| :| :| :| :| :|
        EOL::Db.truncate_all_tables
        self.load_with_caching(scenario_name)
      end
    end

    def self.load_with_caching(name)
      loader = self.new(name)
      loader.load_with_caching
    end

    def initialize(name)
      @name = name
      @all_connections = EOL::Db.all_connections
      @we_have_already_cached_this_scenario = false
    end

    def load_with_caching
      if !@we_have_already_cached_this_scenario && cached_files_are_stale?
        load_and_cache
      elsif @we_have_already_cached_this_scenario && is_the_data_in_the_database?
        Rails.logger.warn("** WARNING: You attempted to load the #{@name} " \
          "scenario twice, here. Please remove the call or truncate tables, " \
          "first.")
      else
        @all_connections.each do |conn|
          load_cache_for_connection(conn)
        end
      end
      @we_have_already_cached_this_scenario = true
    end

    private

    def cached_files_are_stale?
      @all_connections.each do |conn|
        # If there's no file at all, call it 'stale':
        return true unless File.exists?(mysqldump_path_for_connection(conn))
      end
      last_compile = time_the_dumps_were_taken
      return true if !last_compile
      # Hard-coded, which sucks, but we NEED this one...
      return true if cached_file_is_stale?('foundation', last_compile)
      return cached_file_is_stale?(@name, last_compile)
    end

    def cached_file_is_stale?(name, last_compile)
      last_modified = File.mtime(Rails.root.join('scenarios', "#{name}.rb"))
      return true if last_compile < last_modified
      return true if migrations_have_been_created_since_compile?
      return false
    end

    def migrations_have_been_created_since_compile?
      !`find #{Rails.root.join('db', 'migrate')} -type f -newer #{mysqldump_path_for_connection(@all_connections.first)}`.blank?
    end

    def load_and_cache
      Rails.logger.warn "&& Creating #{@name} cache.  Please be patient."
      EolScenario.load @name
      remember_that_this_is_loaded
      create_cache
    end

    def is_the_data_in_the_database?
      User.find_by_username(already_loaded_username)
    end

    def load_cache_for_connection(conn)
      mysqldump_path = mysqldump_path_for_connection(conn)
      IO.read(mysqldump_path).to_s.split(/;\s*[\r\n]+/).each do |cmd|
        if cmd =~ /\w/m # Only run commands with text in them.  :)  A few were "\n\n".
          conn.execute cmd.strip
        end
      end
    end

    # the last time the dumps were taken
    def time_the_dumps_were_taken
      last_compiled = nil
      @all_connections.each do |conn|
        mysqldump_path = mysqldump_path_for_connection(conn)
        if File.exists?(mysqldump_path)
          this_dump_modified = File.mtime(mysqldump_path)
          if !last_compiled || this_dump_modified < last_compiled # We want the earliest change.
            last_compiled = File.mtime(mysqldump_path)
          end
        end
      end
      last_compiled
    end

    def remember_that_this_is_loaded
      User.gen :username => already_loaded_username
    rescue ActiveRecord::RecordNotUnique => e
      puts "** WARNING: Somehow managed to load #{@name} scenario twice."
    end

    def already_loaded_username
      "#{@name}_already_loaded"[0..31]
    end

    def create_cache
      @all_connections.each do |conn|
        tables = tables_to_export_from_connection(conn)
        db_config_hash = conn.raw_connection.query_options
        mysql_params = []
        if v = db_config_hash[:host]
          mysql_params << "--host='#{v}'"
        end
        if v = db_config_hash[:username]
          mysql_params << "--user='#{v}'"
        end
        if v = db_config_hash[:password]
          mysql_params << "--password='#{v}'"
        end
        if v = db_config_hash[:encoding]
          mysql_params << "--default-character-set='#{v}'"
        end
        mysqldump_cmd = $MYSQLDUMP_COMPLETE_PATH + " #{mysql_params.join(' ')} --compact --no-create-info #{db_config_hash[:database]} #{tables.join(' ')}"
        result = `#{mysqldump_cmd}`
        # the next two lines will vastly speed up the import
        result = "SET AUTOCOMMIT = 0;\nSET FOREIGN_KEY_CHECKS=0;\nUSE `#{db_config_hash[:database]}`;\n" +
                  result +
                 "SET FOREIGN_KEY_CHECKS = 1;\nCOMMIT;\nSET AUTOCOMMIT = 1;\n"
        result.gsub!(/INSERT/, 'INSERT IGNORE')
        mysqldump_path = mysqldump_path_for_connection(conn)
        File.open(mysqldump_path, 'w') {|f| f.write(result) }
        @we_have_already_cached_this_scenario = true
      end
    end

    # No sense in exporting empty tables...
    def tables_to_export_from_connection(conn)
      tables = []
      conn.tables.each do |table|
        next if table == 'schema_migrations'
        count_rows = conn.execute("SELECT 1 FROM `#{table}` LIMIT 1").count
        tables << table if count_rows > 0
      end
      tables
    end

    def mysqldump_path_for_connection(conn)
      mysqldump_path = Rails.root.join('tmp', "#{conn.raw_connection.query_options[:database]}_for_#{@name}_scenario.sql")
    end

  end
end
