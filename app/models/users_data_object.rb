class UsersDataObject < ActiveRecord::Base
  validates_presence_of :user_id, :data_object_id
  validates_uniqueness_of :data_object_id

  has_one :user
  has_one :data_object
end