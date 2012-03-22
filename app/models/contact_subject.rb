# A kind of topic for any given Contact (q.v.).
class ContactSubject < ActiveRecord::Base
  uses_translations
  has_many :contacts
  validates_presence_of :recipients
  
end
