module EOL
  module Api
    METHODS = [ :ping, :pages, :search, :collections, :data_objects, :hierarchy_entries, :hierarchies, :provider_hierarchies, :search_by_provider ]

    def self.default_version_of(method)
      begin
        method_class = "EOL::Api::#{method.to_s.camelize}".constantize
        "#{method_class}::V#{method_class::DEFAULT_VERSION.tr('.', '_')}".constantize
      rescue
        return nil
      end
    end
  end
end