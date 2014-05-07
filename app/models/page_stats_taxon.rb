# This table provides access to some cached species page stastics generated nightly
# by an automated script that runs the appropriate queries
class PageStatsTaxon < ActiveRecord::Base

  # TODO - date_created ?!?  How about created_at ? At least created_on...
  def self.latest
    self.order('date_created desc').first
  end

end
