# This library file declares extensions to the Core classes, as well as some of the "Core" Rails classes
# (ActiveRecord and what-not).

# This is defined in /confif/initializers so this will be added to ActiveRecord before the model classes
# are loaded as this method is needed when some classes are loaded

class ActiveRecord::Base
  def self.establish_master_connection(database_name)
    if Rails.env.test?
      # we are now using a separate environment for testing called test_master
      # this is so we can test read/write splitting. It is not an actual replication
      # setup therefore not a real master
      master_database_name = "test_master_" + database_name.to_s
      raise "There is no entry for `#{master_database_name}` in /config/database.yml" if configurations[master_database_name].blank?
      self.establish_connection configurations[master_database_name]
    elsif Rails.env.development? || Rails.env.staging_dev_cache?
      # the development environment always uses the same databases for master and slave
      master_database_name = "#{Rails.env}_#{database_name}"
      self.establish_connection configurations[master_database_name]
    else
      # in all other cases raise an error if the master_*_database isn't configured
      master_database_name = "master_#{database_name.to_s}_database"
      raise "There is no entry for `#{master_database_name}` in /config/database.yml" if configurations[master_database_name].blank?
      self.establish_connection configurations[master_database_name]
    end
  end
end
