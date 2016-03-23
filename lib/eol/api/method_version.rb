module EOL
  module Api
    class MethodVersion
      VERSION = nil
      BRIEF_DESCRIPTION = nil
      DESCRIPTION = nil
      TEMPLATE = nil
      PARAMETERS = nil

      class << self
        Rails.application.routes.default_url_options[:host] = ActionMailer::Base.default_url_options[:host] || EOL::Server.domain
        include Rails.application.routes.url_helpers # for using user_url(id) type methods

        def brief_description
          call_proc_or_return_value(self::BRIEF_DESCRIPTION)
        end

        def description
          call_proc_or_return_value(self::DESCRIPTION)
        end

        def parameters
          call_proc_or_return_value(self::PARAMETERS)
        end

        def call_proc_or_return_value(proc_or_value)
          return proc_or_value.call if proc_or_value.class == Proc
          proc_or_value
        end

        def view_context
          ApiController.new.view_context
        end

        def validate_and_normalize_input_parameters!(input_params)
          I18n.locale = :en
          parameters.each do |documented_parameter|
            if incoming_value = input_params[documented_parameter.name]
              if documented_parameter.boolean?
                incoming_value = convert_to_boolean(incoming_value)
              elsif documented_parameter.integer?
                if incoming_value.is_int?
                  incoming_value = incoming_value.to_i
                else
                  incoming_value = documented_parameter.default
                end
              end

              # verify ranges
              if documented_parameter.range?
                incoming_value = documented_parameter.values.max if incoming_value > documented_parameter.values.max
                incoming_value = documented_parameter.values.min if incoming_value < documented_parameter.values.min
              end
              # verify enumerated lists
              if documented_parameter.array?
                incoming_value.downcase! if incoming_value.class == String
                incoming_value = documented_parameter.default unless documented_parameter.values.include?(incoming_value)
              end
              if documented_parameter.string? && incoming_value == ''
                incoming_value = nil
              end
              input_params[documented_parameter.name.to_sym] = incoming_value
            else
              input_params[documented_parameter.name.to_sym] = documented_parameter.default
            end

            # validate required parameters
            if documented_parameter.required? && input_params[documented_parameter.name.to_sym] == nil
              raise EOL::Exceptions::ApiException.new("Required parameter \"#{documented_parameter.name}\" was not included")
            end
          end
          input_params
        end

        def convert_to_boolean(param)
          return false if [ nil, '', '0', 0, 'false', false ].include?(param.downcase)
          true
        end

        def method_name
          # EOL::Api::ProviderHierarchies::V1_0 => provider_hierarchies
          self.parent.to_s.split("::").last.underscore
        end

        def other_versions
          self.parent::VERSIONS - [ self::VERSION ]
        end
      end
    end
  end
end
