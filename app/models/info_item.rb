class InfoItem < ActiveRecord::Base
  uses_translations
  belongs_to :toc_item, :foreign_key => :toc_id 
  has_many   :data_objects_info_items
  has_many   :data_objects, :through => :data_objects_info_items

  def self.get_schema_value    
    arr_SPM = InfoItem.connection.execute("SELECT schema_value, id FROM info_items ORDER BY id").all_hashes
    return arr_SPM
  end
end
