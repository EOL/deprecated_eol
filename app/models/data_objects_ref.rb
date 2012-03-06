class DataObjectsRef < ActiveRecord::Base

  belongs_to :data_object
  belongs_to :ref

end
