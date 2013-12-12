# I'm not entirely sure what this is, but it has something to do with outlinks to content partners. You'll see it being used by
# #hierarchy_outlink_collection_types, which is a helper method, and that's used on the taxa resources / partners tab.
#
# TODO - explain this class.  :\
class CollectionType < ActiveRecord::Base
  uses_translations
  acts_as_tree order: 'lft'
  
  has_and_belongs_to_many :collections
  
  def materialized_path_labels

    parent_path = (parent_id == 0 || parent.nil?) ? '' : parent.materialized_path_labels + ' ('
    return parent_path + label + ((parent_id == 0 || parent.nil?) ? '' : ')')

  end
  
end
