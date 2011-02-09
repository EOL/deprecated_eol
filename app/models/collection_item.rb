class CollectionItem < ActiveRecord::Base

  belongs_to :collection
  belongs_to :object, :polymorphic => true

  validates_presence_of :object_id, :object_type, :name

end
