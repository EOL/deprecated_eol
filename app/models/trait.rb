class Trait < ActiveRecord::Base
  belongs_to :association, class: "HierarchyEntry", foreign_key: "node_id"
  belongs_to :predicate, class: "KnownUri"
  belongs_to :inverse, class: "KnownUri"
  belongs_to :value, class: "KnownUri"
  belongs_to :sex, class: "KnownUri"
  belongs_to :lifestage, class: "KnownUri"
  belongs_to :stat_method, class: "KnownUri"
  belongs_to :units, class: "KnownUri"

  has_many :contents, as: :item
  has_many :content_curations, through: :contents
  has_many :nodes, through: :contents, class_name: "HierarchyEntry"
  has_many :pages, through: :nodes, class_name: "TaxonConcept"
end
