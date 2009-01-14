class ContactSubject < ActiveRecord::Base

  has_many :contacts
  validates_presence_of :recipients,:title
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: contact_subjects
#
#  id         :integer(4)      not null, primary key
#  active     :boolean(1)      not null, default(TRUE)
#  recipients :string(255)
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime

