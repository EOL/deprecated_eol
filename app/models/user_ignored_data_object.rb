class UserIgnoredDataObject < ActiveRecord::Base
  
  validates_presence_of :user_id, :data_object_id
  
  belongs_to :user
  belongs_to :data_object
end
