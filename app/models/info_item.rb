class InfoItem < ActiveRecord::Base
  uses_translations
  belongs_to :toc_item, :foreign_key => :toc_id 
  has_many   :data_objects_info_items
  has_many   :data_objects, :through => :data_objects_info_items
end
