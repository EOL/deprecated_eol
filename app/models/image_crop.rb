class ImageCrop < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :user
  belongs_to :representative_language, class_name: Language.to_s

  attr_accessible :data_object_id, :user_id, :original_object_cache_url, :new_object_cache_url
end
