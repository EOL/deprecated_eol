# Enumerated list of statuses for an ContentPartner.  For now, mainly distinguishing between active, archived, and pending
# agents.
class ContentPartnerStatus < ActiveRecord::Base

  uses_translations

  has_many :content_partners

  include NamedDefaults

  set_defaults :label,
    %w{Active Archived Pending Inactive}

end
