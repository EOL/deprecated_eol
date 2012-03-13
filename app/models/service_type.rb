class ServiceType < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :resources
end