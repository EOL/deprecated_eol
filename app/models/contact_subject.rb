# A kind of topic for any given Contact (q.v.).
class ContactSubject < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :contacts
  validates_presence_of :recipients
  
end
