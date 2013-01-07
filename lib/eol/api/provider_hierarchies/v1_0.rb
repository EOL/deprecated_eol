module EOL
  module Api
    module ProviderHierarchies
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:lists_the_identifiers_for_all_hierarchies) }
        DESCRIPTION = Proc.new { I18n.t(:provider_hierarchies_method_description) }
        PARAMETERS = [ ]

        def self.call(params={})
          return_hash = []
          Hierarchy.available_via_api.collect do |h|
            { 'id' => h.id, 'label' => h.label }
          end
        end

      end
    end
  end
end
