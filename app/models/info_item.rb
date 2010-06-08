class InfoItem < SpeciesSchemaModel
  belongs_to :toc_item, :foreign_key => :toc_id 
  has_many   :data_objects_info_items
  has_many   :data_objects, :through => :data_objects_info_items


  def self.get_schema_value    
    arr_SPM = SpeciesSchemaModel.connection.execute("SELECT schema_value, id FROM info_items ORDER BY id").all_hashes
    return arr_SPM
  end

  def self.get_toc_breakdown
    arr_toc = SpeciesSchemaModel.connection.execute("SELECT toc2.label major_heading, toc.label sub_heading, ii.label spm
    FROM table_of_contents toc 
    LEFT JOIN table_of_contents toc2 ON toc.parent_id = toc2.id
    JOIN info_items ii ON ii.toc_id = toc.id Order By toc.view_order Asc").all_hashes
    return arr_toc
  end


end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: info_items
#
#  id           :integer(2)      not null, primary key
#  toc_id       :integer(2)      not null
#  label        :string(255)     not null
#  schema_value :string(255)     not null

