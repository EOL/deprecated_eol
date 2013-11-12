# Represents different ways of displaying data, based on the type of user (audience).  For example, this will allow us to show
# data objects that are written for a younger audience when it's appropriate.
class Audience < ActiveRecord::Base
  uses_translations
  has_and_belongs_to_many :data_objects
end
