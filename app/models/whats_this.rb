class WhatsThis < ActiveRecord::Base
  def self.get_url_for_name(name)
    wt = WhatsThis.find_by_name(name.downcase)
    wt ? wt.url : wt # Returns nil if there wasn't one, else just the url (string).
  end
end
