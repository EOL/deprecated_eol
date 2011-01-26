class ListItem < ActiveRecord::Base

  belongs_to :list
  belongs_to :object, :polymorphic => true

  validates_presence_of :object_id, :object_type, :name

end
