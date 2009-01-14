class DataObjectLogDaily < LogDaily
  set_unique_data_column :integer, :data_object_id
  
  attr_reader :object_url
  attr_reader :object_id
  attr_reader :object_type
  attr_reader :object_description
  
  # OPTIMIZE this'll do one query per row ... ouchies ... i wanna cache to hit  :(
  def unique_data_to_s
    object = DataObject.find(unique_data,:include=>:data_type)
    @object_type=object.data_type.label.downcase
    @object_id=object.id
    @object_description=object.description
    if object.image?
      @object_url=object.smart_medium_thumb 
    elsif object.map?
      @object_url=object.map_image     
    end
    "[#{ object.data_type.label }] #{ object.description[0,40] }"
  end
  
end
