module EOL
  module Api
    module Ping
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:returns_either_a_positive_or_negative_response) }
        DESCRIPTION = Proc.new { I18n.t(:ping_method_description) }
        PARAMETERS = [ ]

        def self.call(params={})
          return { 'response' => { 'message' => 'Success' } }
        end
      end
    end
  end
end
