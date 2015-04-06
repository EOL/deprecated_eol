class Trait < ActiveRecord::Base
  has_many :contents, as: :item
  has_many :content_curations, through: :contents
  has_many :nodes, through: :contents, class_name: "HierarchyEntry"
  has_many :pages, through: :nodes, class_name: "TaxonConcept"
end
