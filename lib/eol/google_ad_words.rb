module EOL
  module GoogleAdWords

    def self.create_signup_conversion
      Conversion.new(:id => 1013677372, :label => "O9CDCPyliwIQvPqt4wM", :value => 20)
    end

    class Conversion
      attr_accessor :id, :label, :value
      def initialize(settings = {})
        @id = settings[:id]
        @label = settings[:label]
        @value = settings[:value]
      end
    end
  end
end
