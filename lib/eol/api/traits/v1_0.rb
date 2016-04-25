module EOL
  module Api
    module Traits
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = ""
        DESCRIPTION = ""
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true)
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          I18n.locale = params[:language] unless params[:language].blank?
          PageTraits.new(params[:id]).jsonld
        end
      end
    end
  end
end
