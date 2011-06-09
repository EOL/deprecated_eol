# I think (but TODO is to review this) that this is a TC-specific, quick way to look up who curated the concept and when,
# rather than trying to get that info from CuratorActivityLog (qv).  ...I am not convinced this is worthwhile.
class LastCuratedDate < ActiveRecord::Base

  validates_presence_of :user, :taxon_concept, :last_curated

  belongs_to :user
  belongs_to :taxon_concept

end
