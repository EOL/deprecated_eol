module EOL
  module GoogleAdWords

    def self.create_signup_conversion
      Conversion.new(:id => 1013677372, :label => "O9CDCPyliwIQvPqt4wM", :value => 20, :format => EOL::GoogleAdWords.no_notification)
    end

    def self.no_notification
      3
    end

    class Conversion
      attr_accessor :format, :id, :label, :value
      def initialize(settings = {})
        @id = settings[:id]
        @format = settings[:format]
        @label = settings[:label]
        @value = settings[:value]
      end
    end
  end
end
