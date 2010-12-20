# This table associates the DataObject UntrustReason with an ActionHistory so we can know
# why a curator made a particular change
class ActionsHistoriesUntrustReason < ActiveRecord::Base

  belongs_to :actions_history
  belongs_to :untrust_reason

end