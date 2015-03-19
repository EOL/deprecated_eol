class InstitutionalSponsor < ActiveRecord::Base
  scope :active, where(active: true)
  
  def self.get_active_sponsors_with_limit
    InstitutionalSponsor.active.sort.take($SPONSORS_ON_HOME_PAGE)
  end
end
