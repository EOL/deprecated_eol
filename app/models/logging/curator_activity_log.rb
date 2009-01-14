class CuratorActivityLog < LoggingModel
  
  self.abstract_class = true
  
  belongs_to :curator_activity  
  validates_presence_of :curator_activity
  
  belongs_to :user  
  validates_presence_of :user

  belongs_to :curator_activity
  validates_presence_of :curator_activity
  alias_attribute :activity, :curator_activity

end
