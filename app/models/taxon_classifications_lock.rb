class TaxonClassificationsLock < ActiveRecord::Base
  has_many :taxon_concepts
end
