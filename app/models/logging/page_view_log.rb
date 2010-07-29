class PageViewLog < LoggingModel
  
  belongs_to :user
  belongs_to :agent
  belongs_to :taxon_concept
  
end
