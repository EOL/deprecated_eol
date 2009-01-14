# An log entry for an action a curator performed on a +DataObject+.
class CuratorDataObjectLog < CuratorActivityLog
  
  belongs_to :data_object
  alias_attribute :object, :data_object
  
  validates_presence_of :data_object
  
end
