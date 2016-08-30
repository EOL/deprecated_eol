module EOL
  module Db
    @@db_defaults = {
      :charset   => ENV['CHARSET']   || 'utf8',
      :collation => ENV['COLLATION'] || 'utf8_general_ci'
    }

    class << self
      def all_connections
        connections = [ActiveRecord::Base, LoggingModel]
        connections.map {|c| c.connection}
      end

      def clear_temp
        ls = Dir.glob(Rails.root.join("tmp", "*_#{Rails.env}_*sql")) +
             Dir.glob(Rails.root.join("tmp", "*_#{Rails.env}_*yml"))
        ls.each { |file| File.delete(file) }
      end

      def create
        arb_conf = Rails.configuration.database_configuration[Rails.env.to_s]
        log_conf = Rails.configuration.database_configuration["#{Rails.env}_logging"]
        ActiveRecord::Base.establish_connection({'database' => ''}.reverse_merge!(arb_conf))
        ActiveRecord::Base.connection.create_database(arb_conf['database'], arb_conf.reverse_merge!(@@db_defaults))
        ActiveRecord::Base.establish_connection(arb_conf)
        LoggingModel.establish_connection({'database' => ''}.reverse_merge!(log_conf))
        LoggingModel.connection.create_database(log_conf['database'], log_conf.reverse_merge!(@@db_defaults))
        LoggingModel.establish_connection(log_conf)
      end

      def drop
        raise "This action is ONLY available in the development and test environments." unless
          Rails.env.development? || Rails.env.development_master? || Rails.env.test? || Rails.env.test_master?
        EOL::Db.all_connections.each do |connection|
          connection.drop_database connection.current_database
        end
      end

      def recreate
        Rake::Task['solr:start'].invoke
        EOL::Db.drop
        EOL::Db.create
        # TODO - we should have a "clear everything" task.  :|
        EOL::Db.clear_temp
        # Ensure everything else is cleared out:
        Rails.cache.clear
        # TODO - move this to ... somewhere it belongs:
        solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
        solr.delete_all_documents
        # Then build the databases:
        Rake::Task['db:migrate'].invoke
      end

      def rebuild
        EOL::Db.recreate
        # TODO - this is broken. For some reason, the following build fails... But
        # if you run "scnarios:lead NAME=bootstrap" as a separate command, it
        # works just fine. ...Need to figure out what's going wrong with a
        # properly-placed debugger.  :\
        # This looks like duplication with #populate, but it skips truncating, since the DBs are fresh.  Faster:
        # TODO - still no reason you couldn't extract this.  :|
        ENV['NAME'] = 'bootstrap'
        # Not sure if reload will work, but otherwise the following will fail; the
        # wrong models are loaded into memory at this point.
        # reload!
        Rake::Task['scenarios:load'].invoke
        Rake::Task['solr:rebuild_all'].invoke
      end

      def reset
        EOL::Db.clear_temp
        # NOTE: this truncates and "forgets everything" before each:
        EOL::ScenarioLoader.load_all_with_caching
        EOL.forget_everything # NOTE: runing this again to ensure it's clear.
      end

      def populate
        Rake::Task['solr:start'].invoke
        Rake::Task['truncate'].invoke
        ENV['NAME'] = 'bootstrap'
        EOL::Db.clear_temp
        Rake::Task['scenarios:load'].invoke
        Rake::Task['solr:rebuild_all'].invoke
      end

      # truncates all tables in all databases
      def truncate_all_tables(options = {})
        options[:verbose] ||= false
        EOL::Db.all_connections.uniq.each do |conn|
          count = 0
          conn.tables.each do |table|
            next if table == 'schema_migrations'
            count += 1
            if conn.respond_to? :with_master
              conn.with_master do
                truncate_table(conn, table)
              end
            else
              truncate_table(conn, table)
            end
          end
          if options[:verbose]
            puts "-- Truncated #{count} tables in " +
              conn.instance_eval { @config[:database] } +
              "."
          end
        end
        # EOL.forget_everything # expensive, but without it, would risk errors.
      end

      def truncate_table(conn, table)
        conn.execute "TRUNCATE TABLE `#{table}`"
      end

      # This is a little ... raw. You pass in the class, an ordered array of the
      # fields represented by the data, and the data as an array _of strings_
      # (because we don't know how you want them quoted, without doing a bunch of
      # work—KISS ...and faster), with the fields quoted and in the same order as
      # the fields. TODO - this would be better with a hash rather than two
      # arrays.
      def bulk_insert(klass, fields, rows, options = {})
        table = klass.table_name
        table += "_tmp" if options[:tmp]
        fields = Array(fields)
        EOL.log("EOL::Db#bulk_insert #{rows.count} rows into #{table}",
          prefix: '.') unless options[:silent]
        in_groups_with_logged_time(Array(rows), 2000) do |group|
          klass.connection.execute(
            "INSERT #{options[:ignore] ? 'IGNORE ' : ''} INTO #{table} "\
            "(`#{fields.join("`, `")}`) "\
            "VALUES (#{group.join("), (")})"
          )
        end
      end

      # TODO: use this!
      def in_groups_with_logged_time(rows, group_size, &block)
        size = rows.size
        done = 0
        start = Time.now
        group_num = 0
        groups = size / group_size
        groups += 1 unless size % group_size == 0
        warn_threshold = group_size * 50
        rows.in_groups_of(group_size, false) do |group|
          yield(group)
          group_num += 1
          if size > warn_threshold && group_num % 10 == 1
            done += group.size
            elapsed = Time.now - start
            pct = done / size.to_f * 100
            time_per_group = elapsed / group_num
            groups_remaining = groups - group_num
            time_remaining = (groups_remaining * time_per_group).to_i
            EOL.log("group #{group_num} (#{done}/#{size}, "\
              "#{pct.round(3)}%, #{time_remaining}s remaining)",
              prefix: ".")
          end
        end
      end

      def with_tmp_tables(klasses, &block)
        begin
          Array(klasses).each do |klass|
            klass.connection.
              execute("DROP TABLE IF EXISTS #{klass.table_name}_tmp")
            klass.connection.execute("CREATE TABLE #{klass.table_name}_tmp "\
              "LIKE #{klass.table_name}")
          end
          yield
        ensure
          Array(klasses).each do |klass|
            klass.connection.
              execute("DROP TABLE IF EXISTS #{klass.table_name}_tmp")
          end
        end
      end

      # NOTE: ensures that there is at least one row in the tmp table! So you
      # cannot swap an empty table into place, sorry.
      def swap_tmp_table(klass)
        EOL.log_call
        count = begin
          klass.connection.select_value("SELECT COUNT(*) "\
            "FROM #{klass.table_name}_tmp")
        rescue
          0
        end
        if count > 0
          klass.connection.execute("RENAME TABLE #{klass.table_name} "\
            "TO #{klass.table_name}_swap, "\
            "#{klass.table_name}_tmp TO #{klass.table_name}, "\
            "#{klass.table_name}_swap TO #{klass.table_name}_tmp")
        end
      end

      def update_ignore_id_by_field(klass, id1, id2, field)
        raise "Danger: field '#{field}' not allowed on #{klass}" unless
          klass.columns.map(&:name).include?(field.to_s)
        klass.connection.execute(
          sanitize_array(["UPDATE IGNORE #{klass.table_name} "\
            "SET #{field} = ? WHERE #{field} = ?", id1, id2])
        )
        klass.where(["#{field} = ?", id2]).delete_all
      end

      def update_ignore_ids_by_field(klass, id1, ids, field)
        raise "Danger: field '#{field}' not allowed on #{klass}" unless
          klass.columns.map(&:name).include?(field.to_s)
        klass.connection.execute(
          sanitize_array(["UPDATE IGNORE #{klass.table_name} "\
            "SET #{field} = ? WHERE #{field} IN (?)", id1, ids])
        )
        klass.where(["#{field} IN (?)", ids]).delete_all
      end

      def delete_all_batched(klass, where)
        total = 0
        count = 0
        where = sanitize_array(where) if where.is_a?(Array)
        begin
          count = klass.with_master do
            klass.connection.send(:delete_sql,
              "DELETE FROM `#{klass.table_name}` where #{where} LIMIT 1000")
          end
          total += count
        end while count > 0
        total
      end

      def sanitize_array(array)
        ActiveRecord::Base.send(:sanitize_sql_array, array)
      end
    end
  end
end
