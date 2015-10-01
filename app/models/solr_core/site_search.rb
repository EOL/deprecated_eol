module SolrCore
  class SiteSearch < SolrCore::Base
    CORE_NAME = "site_search"

    def initialize
      connect(CORE_NAME)
    end
  end
end
