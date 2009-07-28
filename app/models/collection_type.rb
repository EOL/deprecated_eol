class CollectionType < SpeciesSchemaModel
  acts_as_tree :order => 'lft'
  
  has_and_belongs_to_many :collections
  
  
  def materialized_path_labels
    if parent_id == 0 || parent.nil?
      parent_path = ''
    else
      parent_path = parent.materialized_path_labels + ' / '
    end
    return parent_path + label
  end
end