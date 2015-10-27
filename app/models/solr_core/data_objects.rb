module SolrCore
  class DataObjects < SolrCore::Base
    CORE_NAME = "data_objects"

    def initialize
      connect(CORE_NAME)
    end
  end
end
