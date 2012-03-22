class ServiceType < ActiveRecord::Base
  uses_translations
  has_many :resources
end