module EOL
  module Sparql
    class UnitQueryBuilder

      def initialize(unit_uri, min_value, max_value)
        @unit_uri = unit_uri
        @min_value = min_value
        @max_value = max_value
        raise unless @unit_uri.is_a?(String)
        raise unless @min_value.nil? || @min_value.is_a?(Fixnum) || @min_value.is_a?(Float)
        raise unless @max_value.nil? || @max_value.is_a?(Fixnum) || @max_value.is_a?(Float)
      end

      def sparql_query_filters
        magnitudes = all_magnitudes( [ @unit_uri ])
        filter_components = [ filter_conditional(identical_uris(@unit_uri), @min_value, @max_value) ]
        magnitudes.each do |info|
          converted_min = @min_value
          converted_max = @max_value
          info[:functions].each{ |f| converted_min = f.call(converted_min) } unless converted_min.nil?
          info[:functions].each{ |f| converted_max = f.call(converted_max) } unless converted_max.nil?
          filter_components << filter_conditional(info[:uris], converted_min, converted_max)
        end
        "FILTER((#{filter_components.join(') || (')})) . "
      end

      def filter_conditional(unit_uris, min, max)
        conditional = "?unit_of_measure_uri IN (<#{unit_uris.join('>,<')}>)"
        conditional << " && xsd:float(?value) >= xsd:float(#{min})" unless min.nil?
        conditional << " && xsd:float(?value) <= xsd:float(#{max})" unless max.nil?
        conditional
      end

      def identical_uris(unit_uri)
        if conversion = DataPointUri.conversions.detect{ |c| c[:starting_units].include?(unit_uri) }
          conversion[:starting_units]
        else
          [ unit_uri ]
        end
      end

      def all_magnitudes(starting_unit_uris)
        magnitudes = magnitude_conversions(starting_unit_uris)
        return [] if magnitudes.empty?

        # get conversions of conversions (of conversions, etc...)
        starting_length = 0
        while starting_length < magnitudes.length
          starting_length = magnitudes.length
          new_magnitudes = magnitudes.dup
          magnitudes.each do |info|
            next_level_conversions = magnitude_conversions(info[:uris])
            # we don't need multiple ways to arrive at the same unit; prevents loops
            next_level_conversions.delete_if{ |c| magnitudes.collect{ |m| m[:conversion] }.include?(c[:conversion]) }
            # prepend the conversion from the the starting unit to the basis for the next conversions
            next_level_conversions.each{ |c| c[:functions] = info[:functions] + c[:functions] }
            # modifify new_magnitudes with anything it does not yet contain
            new_magnitudes |= next_level_conversions
          end
          magnitudes = new_magnitudes.uniq
        end
        magnitudes
      end

      def magnitude_conversions(starting_unit_uris)
        magnitudes = []
        DataPointUri.conversions.each do |conversion|
          if ! (conversion[:starting_units] & starting_unit_uris).empty?
            magnitudes << {
              conversion: conversion,
              functions: [ conversion[:function] ],
              uris: [ conversion[:ending_unit].uri ] }
          elsif starting_unit_uris.include?(conversion[:ending_unit].uri)
            magnitudes << {
              conversion: conversion,
              functions: [ conversion[:reverse_function] ],
              uris: conversion[:starting_units] }
          end
        end
        magnitudes
      end

    end
  end
end
