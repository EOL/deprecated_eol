class DataObjectTranslation < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :language
  belongs_to :original_data_object, class_name: DataObject.to_s, foreign_key: :original_data_object_id
end
