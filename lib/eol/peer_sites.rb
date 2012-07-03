# Models using this will need to have a peer_site_id
module EOL
  module PeerSites
    def self.included(base)
      base.belongs_to :peer_site
      base.before_create :add_peer_site_id
    end
    
    def add_peer_site_id
      return unless self.class.column_names.include?('peer_site_id')
      return unless self.peer_site_id.blank? || self.peer_site_id == 0
      self.peer_site_id = PEER_SITE_ID
    end
  end
end
