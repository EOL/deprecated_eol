# TODO: Curators using the worklist tab can ignore data objects.
class WorklistIgnoredDataObject < ActiveRecord::Base
  belongs_to :user
  belongs_to :data_object
end
