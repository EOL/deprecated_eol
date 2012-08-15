# Just a log of how many views pages get. TODO - This is likely redundant (see UserActivity) and can probably be removed.
class PageViewLog < LazyLoggingModel

  belongs_to :user
  belongs_to :agent
  belongs_to :taxon_concept

end
