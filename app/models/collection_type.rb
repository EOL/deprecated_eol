class CollectionType < SpeciesSchemaModel
  acts_as_tree :order => 'lft'
  
  has_and_belongs_to_many :collections
  
  def materialized_path_labels

    parent_path = (parent_id == 0 || parent.nil?) ? '' : parent.materialized_path_labels + ' ('
    return parent_path + label + ((parent_id == 0 || parent.nil?) ? '' : ')')

  end
  
end