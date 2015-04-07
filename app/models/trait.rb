# NOTE: you should not just read the value from a Trait; it could be a Uri, it
# could be a literal (and that literal could be a number or a string).
class Trait < ActiveRecord::Base
  belongs_to :associated_to, class: "HierarchyEntry"
  belongs+to :added_by_user, class: "User"
  belongs_to :predicate, class: "KnownUri"
  belongs_to :inverse, class: "KnownUri"
  belongs_to :value_uri, class: "KnownUri"
  belongs_to :sex, class: "KnownUri"
  belongs_to :lifestage, class: "KnownUri"
  belongs_to :stat_method, class: "KnownUri"
  belongs_to :units, class: "KnownUri"

  has_many :contents, as: :item
  has_many :content_curations, through: :contents
  has_many :nodes, through: :contents, class_name: "HierarchyEntry"
  has_many :pages, through: :nodes, class_name: "TaxonConcept"

  # This feels dirty. ...But appears to be the most accurate method:
  def value
    return @value if @value
    return @value = value_uri if value_uri_id
    @value = begin
      Float(value_literal)
    rescue
      Integer(value_literal)
    rescue
      value_literal
    end
  end
end
