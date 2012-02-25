# Denomralized information about a hierarchy entry (NOT a hierarchy); tells us about images, text content, etc.
class HierarchiesContent < ActiveRecord::Base
  set_table_name 'hierarchies_content'
  belongs_to :hierarchy_entry
  set_primary_key :hierarchy_entry_id
end
