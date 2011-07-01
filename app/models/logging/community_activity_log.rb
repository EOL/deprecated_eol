class CommunityActivityLog < LoggingModel
  belongs_to :community
  belongs_to :user # Who took the action
  belongs_to :activity # What happened
  belongs_to :member # ONLY if it affected one
  belongs_to :collection # ONLY if it affected one
  belongs_to :member_privilege # ONLY if it affected one
end
