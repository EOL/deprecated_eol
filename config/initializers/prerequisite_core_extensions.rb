# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).

# This is defined in /confif/initializers so this will be added to ActiveRecord before the model classes
# are loaded as this method is needed when some classes are loaded

class ActiveRecord::Base
  def self.establish_master_connection(database_name)
    master_database_name = "master_#{database_name.to_s}_database"
    if RAILS_ENV == 'test' || RAILS_ENV == 'development'
      self.establish_connection configurations[RAILS_ENV + "_" + database_name.to_s]
    else
      raise "There is no entry for `#{master_database_name}` in /config/database.yml" if configurations[master_database_name].blank?
      self.establish_connection configurations[master_database_name]
    end
  end
end