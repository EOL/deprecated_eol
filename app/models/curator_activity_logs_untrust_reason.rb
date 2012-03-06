class CuratorActivityLogsUntrustReason < ActiveRecord::Base
  belongs_to :curator_activity_log
  belongs_to :untrust_reason
end
