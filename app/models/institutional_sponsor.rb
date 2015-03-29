class InstitutionalSponsor < ActiveRecord::Base
  scope :active, where(active: true)
  
  def self.get_active_sponsors_with_limit
    InstitutionalSponsor.active.order(:name).take($SPONSORS_ON_HOME_PAGE)
  end
end
