class CollectionActivityLog < LoggingModel
  belongs_to :collection
  belongs_to :collection_item # ONLY if it affected one
  belongs_to :user # Who took the action
  belongs_to :activity # What happened
end
