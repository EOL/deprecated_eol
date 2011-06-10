# This table associates the DataObject UntrustReason with an ActionHistory so we can know
# why a curator made a particular change
class CuratorActivityLogsUntrustReason < ActiveRecord::Base

  belongs_to :curator_activity_log
  belongs_to :untrust_reason

end
