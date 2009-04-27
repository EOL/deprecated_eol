class LastCuratedDate < ActiveRecord::Base
  validates_presence_of :user_id, :taxon_concept_id, :last_curated

  has_one :user
  has_one :taxon_concept
  
end

# == Schema Info
#
# Table name: last_curated_dates
#  id                 :integer(11)      not null, primary key
#  taxon_concept_id   :integer(11)
#  user_id            :integer(11)
#  last_curated       :datetime
