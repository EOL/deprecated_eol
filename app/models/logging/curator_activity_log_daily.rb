class CuratorActivityLogDaily < LoggingModel
  
  belongs_to :user
  validates_presence_of :user
  
end