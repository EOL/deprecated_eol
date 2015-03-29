# This is a class used by Tramea.
#
# This is a self-referential join model, denormalized for pages.
#
#   t.integer :page_id
#   t.integer :ancestor_id
# end
# add_index :descendant_pages, [:page_id, :ancestor_id], name: "pk", unique: true
# add_index :descendant_pages, :page_id
# add_index :descendant_pages, :ancestor_id
class DescendantPage < ActiveRecord::Base
  belongs_to :page
  belongs_to :ancestor, class: "Page"
end
