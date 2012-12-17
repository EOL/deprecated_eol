module EOL
  module Api
    module Pages
      class V0_4 < EOL::Api::MethodVersion
        VERSION = "0.4"
        BRIEF_DESCRIPTION = EOL::Api::Pages::V1_0::BRIEF_DESCRIPTION
        DESCRIPTION = EOL::Api::Pages::V1_0::DESCRIPTION
        PARAMETERS = EOL::Api::Pages::V1_0::PARAMETERS

        def self.call(params={})
          EOL::Api::Pages::V1_0.call(params)
        end

      end
    end
  end
end
