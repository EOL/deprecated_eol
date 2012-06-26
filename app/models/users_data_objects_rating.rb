class UsersDataObjectsRating < ActiveRecord::Base
  belongs_to :user
  belongs_to :data_object
  belongs_to :peer_site
end