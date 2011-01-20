# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).

# This is defined in /confif/initializers so this will be added to ActiveRecord before the model classes
# are loaded as this method is needed when some classes are loaded

class ActiveRecord::Base
  def self.establish_master_connection(database_name)
    master_database_name = "master_#{database_name.to_s}_database"
    if RAILS_ENV == 'test'
      # we are now using a separate environment for testing called test_master
      # this is so we can test read/write splitting. It is not an actual replication
      # setup therefore not a real master
      self.establish_connection configurations["test_master_" + database_name.to_s]
    elsif RAILS_ENV == 'development'
      # the development environment always uses the same databases for master and slave
      self.establish_connection configurations[RAILS_ENV + "_" + database_name.to_s]
    else
      # in all other cases raise an error if the master_*_database isn't configured
      raise "There is no entry for `#{master_database_name}` in /config/database.yml" if configurations[master_database_name].blank?
      self.establish_connection configurations[master_database_name]
    end
  end
end