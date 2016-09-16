module EOL
  class << self
    # NOTE: this assumes the tables are empty. If not, Solr will take a while...
    def forget_everything
      Rails.cache.clear
      ClassVariableHelper.clear_class_variables
      EOL::Solr.rebuild_all
      EOL::Sparql::VirtuosoClient.drop_all_graphs
    end

    def remaining_time(start, done, size)
      elapsed = Time.now - start
      rate = elapsed / done
      time_remaining = (rate * (size - done)).to_i
      if time_remaining < 60
        "#{time_remaining}s"
      elsif time_remaining < (60 * 60)
        minutes = time_remaining / 60
        seconds = time_remaining % 60
        "#{minutes}m#{seconds}s"
      else
        minutes = time_remaining / 60
        hours = minutes / 60
        minutes = minutes % 60
        "#{hours}h#{minutes}m"
      end
    end

    # used to check if a user agent is a robot or not
    def allowed_user_agent?(user_agent)
      return true if user_agent.nil? # When you run specs, it's nil!
      if user_agent.downcase =~ /googlebot|slurp/
        return false
      else
        return true
      end
    end

    # this method expects 'LOGINS_ENABLED' as a string and not $LOGINS_ENABLED which will
    # try to get evaluated as an application global variable
    def global_defined?(variable_name_string)
      # variables must start and end with a letter and can use underscores. Upper and lower cases are allowed
      # e.g. LOGINS_ENABLED
      return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
      return true if self.defined_in_environment?(variable_name_string)
      return true if self.defined_in_database?(variable_name_string)
      return false
    end

    def value_of_global(variable_name_string)
      return nil unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)

      if self.defined_in_environment?(variable_name_string)
        return eval("$#{variable_name_string}")
      elsif option = EolConfig.find_by_parameter(variable_name_string)
        return option.value
      end

      return nil
    end

    def defined_in_environment?(variable_name_string)
      #return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
      return true if eval("defined? $#{variable_name_string}")
      return false
    end

    def defined_in_database?(variable_name_string)
      #return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
      return true if EolConfig.find_by_parameter(variable_name_string)
      return false
    end

    # Intended to (safely) log the name of the method being invoked.
    def log_call
      begin
        (file, method) = caller.first.split
        EOL.log(
          "#{file.split('/').last.split(':')[0..1].join(':')}#"\
          "#{method[1..-2]}", prefix: '#'
        )
      rescue
        EOL.log("Starting method #{caller.first}")
      end
    end

    def log_return
      begin
        (file, method) = caller.first.split
        EOL.log(
          "Return from #{file.split('/').last.split(':')[0..1].join(':')}#"\
          "#{method[1..-2]}", prefix: '#'
        )
      rescue
        EOL.log("Returning from method #{caller.first}")
      end
    end

    def log_error(e)
      EOL.log("ERROR: #{e.message.gsub(/IN \(.*\)/, "IN ([snip])")}", prefix: "!")
      i = 0
      @gem_regex = /(gems|bin)\/(actionpack|activerecord|resque|rake|haml|activesupport|railties|sinatra|unicorn|journey|newrelic_rpm|rack)/
      skipped = 0
      while e.backtrace[i] !~ /__pry__/ &&
        i < e.backtrace.length
        # Skip Rails (unless it's the most proximal stuff)
        if i > 3 && e.backtrace[i] =~ @gem_regex
          skipped += 1
        else
          if skipped > 0
            EOL.log("." * skipped, prefix: "!")
          end
          EOL.log("#{e.backtrace[i]}", prefix: "!")
          skipped = 0
        end
        i += 1
      end
    end

    def log(msg, options = {})
      diff = if @last_log_time
        d = (Time.now - @last_log_time).round(2)
        d == 0 ? "" : "(#{d})"
      else
        ""
      end
      options[:prefix] ||= '*'
      # Have to use #error to get it to show up in production:
      # Apologies for the hard-coded time zone here, but it helps me report on
      # things properly:
      time = Time.now.in_time_zone("Eastern Time (US & Canada)")
      Rails.logger.error("#{options[:prefix]}#{options[:prefix]} "\
        "#{time.strftime("%d-%H:%M:%S.%L")}#{diff} #{msg}")
      Rails.logger.flush if Rails.logger.respond_to?(:flush)
      @last_log_time = time
    end

    # NOTE: Yes, this "really" belongs in EOL::Db, but I didn't want to have to
    # type that when I needed it. :\ NOTE: You really don't _need_ the single-pk
    # version of this. You just want to #pluck(:id) in those cases. I only keep it
    # here to avoid surprise.
    def pluck_pks(klass, query)
      keys = klass.primary_keys || Array(klass.primary_key)
      pluck_fields(keys, query)
    end

    def pluck_fields(fields, query)
      query.pluck("CONCAT(#{fields.map(&:to_s).join(", ',', ")}) f")
    end

    # Black magic to turn fields into hash: ONLY WORKS ON INTEGER FIELDS!
    def unpluck_ids(fields, row)
      Hash[*fields.zip(row.split(",").map(&:to_i)).flatten]
    end

    def spam_re
      @spam_re ||= /\b(movie|watch|episode|putlocker|online free|put-locker|full mkv|http)\b/i
    end

    def wait_for_results(&block)
      results = []
      tries = 0
      while results.empty?
        if tries > 20
          raise "Unable to retrieve results after 20 tries."
        end
        if tries == 1
          EOL.log("WARNING: no results for #{caller.first.split[1]}",
            prefix: "!")
        end
        if tries > 0
          EOL.log("...waiting for results...")
          sleep(10)
        end
        results = yield
        tries += 1
      end
      results
    end
  end
end
