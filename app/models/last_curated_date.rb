class LastCuratedDate < ActiveRecord::Base
  validates_presence_of :user, :taxon_concept, :last_curated

  belongs_to :user
  belongs_to :taxon_concept
  
end

# == Schema Info
#
# Table name: last_curated_dates
#  id                 :integer(11)      not null, primary key
#  taxon_concept_id   :integer(11)
#  user_id            :integer(11)
#  last_curated       :datetime
