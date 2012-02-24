class InfoItem < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  CACHE_ALL_ROWS_DEFAULT_INCLUDES = :toc_item
  uses_translations
  belongs_to :toc_item, :foreign_key => :toc_id 
  has_many   :data_objects_info_items
  has_many   :data_objects, :through => :data_objects_info_items

  def self.get_schema_value    
    arr_SPM = SpeciesSchemaModel.connection.execute("SELECT schema_value, id FROM info_items ORDER BY id").all_hashes
    return arr_SPM
  end
end
