class CommunityActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :community
  belongs_to :user # Who took the action
  belongs_to :activity # What happened
  belongs_to :member # ONLY if it affected one

end
