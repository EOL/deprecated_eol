class SiteConfigurationOption < ActiveRecord::Base
  
  validates_uniqueness_of :parameter
  
end
