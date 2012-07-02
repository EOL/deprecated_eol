class UsersDataObjectsRating < ActiveRecord::Base
  include EOL::PeerSites

  belongs_to :user
  belongs_to :data_object
end