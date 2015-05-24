class CollectionFromListMatch < ActiveRecord::Base
  belongs_to :string, class_name: "CollectionFromListString"

  belongs_to :taxon_concept

  attr_accessible :string_id, :taxon_concept_id
end