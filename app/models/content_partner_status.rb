# Enumerated list of statuses for an ContentPartner.  For now, mainly distinguishing between active, archived, and pending agents.
class ContentPartnerStatus < ActiveRecord::Base
  uses_translations
  has_many :content_partners

  def self.active
    cached_find_translated(:label, 'Active', 'en')
  end

  def self.inactive
    cached_find_translated(:label, 'Inactive', 'en')
  end
end
