module EOL
  module LivesHere

    extend self

    def configure(&block)
      instance_eval(&block)
    end

    def config
      @config ||= Configuration.new
    end

    def config=(value)
      @config = value
    end

    def search(latitude, longitude, options = {})
      query = Query.new(latitude, longitude, options)
      query.execute
    end

    class Configuration

      @@defaults = {
        service: :mol,
        mol: { radius: 50000 }
      }

      class << self

        def defaults
          @@defaults
        end

        def defaults=(value)
          @@defaults = value
        end

      end

      attr_reader :configuration

      def initialize
        @configuration = @@defaults.clone
      end

      def configure(options)
        @configuration = @configuration.deep_merge(options)
      end

      def service
        configuration[:service]
      end

      def mol
        configuration[:mol]
      end

      private

      def configuration=(value)
        @configuration = value
      end

    end

  end
end
