# An log entry for an action a curator performed on a +Comment+.
class CuratorCommentLog < CuratorActivityLog
  belongs_to :comment
  validates_presence_of :comment
end
