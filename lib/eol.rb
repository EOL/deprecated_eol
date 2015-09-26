#
# top level EOL module
#
# we might want to use this for global configuration options or ... anything
#
# it's also useful to have around for namespacing other classes/modules
# in the EOL:: namespace
#
module EOL

  # NOTE: this assumes the tables are empty. If not, Solr will take a while...
  def self.forget_everything
    Rails.cache.clear
    ClassVariableHelper.clear_class_variables
    EOL::Solr.rebuild_all
    EOL::Sparql::VirtuosoClient.drop_all_graphs
  end

  # used to check if a user agent is a robot or not
  def self.allowed_user_agent?(user_agent)
    return true if user_agent.nil? # When you run specs, it's nil!
    if user_agent.downcase =~ /googlebot|slurp/
      return false
    else
      return true
    end
  end

  # this method expects 'LOGINS_ENABLED' as a string and not $LOGINS_ENABLED which will
  # try to get evaluated as an application global variable
  def self.global_defined?(variable_name_string)
    # variables must start and end with a letter and can use underscores. Upper and lower cases are allowed
    # e.g. LOGINS_ENABLED
    return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
    return true if self.defined_in_environment?(variable_name_string)
    return true if self.defined_in_database?(variable_name_string)
    return false
  end

  def self.value_of_global(variable_name_string)
    return nil unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)

    if self.defined_in_environment?(variable_name_string)
      return eval("$#{variable_name_string}")
    elsif option = EolConfig.find_by_parameter(variable_name_string)
      return option.value
    end

    return nil
  end

  def self.defined_in_environment?(variable_name_string)
    #return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
    return true if eval("defined? $#{variable_name_string}")
    return false
  end

  def self.defined_in_database?(variable_name_string)
    #return false unless variable_name_string.match(/^[A-Z]+(_[A-Z]+)*$/i)
    return true if EolConfig.find_by_parameter(variable_name_string)
    return false
  end

  # Intended to (safely) log the name of the method being invoked.
  def self.log_call
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

  def self.log(msg, options = {})
    # return # DISABLING THIS FOR PRODUCTION
    options[:prefix] ||= '*'
    # Have to use #error to get it to show up in production:
    Rails.logger.error("#{options[:prefix]}#{options[:prefix]} "\
      "#{Time.now.strftime("%Y%m%d-%H:%M:%S.%L")} #{msg}")
  end
end
