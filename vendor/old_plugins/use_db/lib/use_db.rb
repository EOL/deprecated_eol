# UseDb

module UseDbPlugin
  # options can have one or the other of the following options:
  #   :prefix - Specify the prefix to append to the RAILS_ENV when finding the adapter secification in database.yml
  #   :suffix - Just like :prefix, only contactentated
  # OR
  #   :adapter
  #   :host
  #   :username
  #   :password
  #     ... etc ... same as the options in establish_connection
  #  
  # Set the following to true in your test environment 
  # to enable extended debugging printing during testing ...
  # UseDbPlugin.debug_print = true   
  #
  
  @@use_dbs = [ActiveRecord::Base]
  @@debug_print = false
  
  def use_db(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options)
    puts "Establishing connecting on behalf of #{self.to_s} to #{conn_spec.inspect}" if UseDbPlugin.debug_print
    establish_connection(conn_spec)
    extend ClassMixin
    @@use_dbs << self unless @@use_dbs.include?(self) || self.to_s.starts_with?("TestModel")
  end
  
  def self.all_use_dbs
    return @@use_dbs
  end
  
  def self.debug_print
    return @@debug_print
  end
  
  def self.debug_print=(newval)
    @@debug_print = newval
  end
  
  module ClassMixin
    def uses_db?
      true
    end
  end  
  
  def get_use_db_conn_spec(options)
    options.symbolize_keys
    suffix = options.delete(:suffix)
    prefix = options.delete(:prefix)
    rails_env = options.delete(:rails_env) || RAILS_ENV
    if (options[:adapter])
      return options
    else
      str = "#{prefix}#{rails_env}#{suffix}"
      connections = YAML.load(ERB.new(IO.read("#{RAILS_ROOT}/config/database.yml"), nil, nil, '_different_erb_out_variable_incase_ERB_is_being_evaluated').result)
      raise "Cannot find database specification.  Configuration '#{str}' expected in config/database.yml" if (connections[str].nil?)      
      return connections[str]
    end
  end
end

class UseDbPluginClass
  extend UseDbPlugin
end
