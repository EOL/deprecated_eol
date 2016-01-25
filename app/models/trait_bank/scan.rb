class TraitBank
  # NOTE: You CANNOT call this "Search," you will get an error. I think we've
  # used that name elsewhere and it conflicts. A Rails 3 problem, that, but I
  # don't care enough to find and fix it.
  class Scan
    class << self
      # LATER:
      # - querystrings
      # - min / max values
      # - units
      # - equivalent values
      #
      # { querystring: @querystring, attribute: @attribute,
      #   min_value: @min_value, max_value: @max_value, page: @page,
      #   offset: @offset, unit: @unit, sort: @sort, language: current_language,
      #   taxon_concept: @taxon_concept,
      #   required_equivalent_attributes: @required_equivalent_attributes,
      #   required_equivalent_values: @required_equivalent_values }
      # TODO: someday we might want to pass in a page size / limit
      def for(search)
        traits = trait_list(options)
        metadata(traits)
      end

      # NOTE: PREFIX eol: <http://eol.org/schema/>
      # PREFIX dwc: <http://rs.tdwg.org/dwc/terms/>
      # e.g.: http://purl.obolibrary.org/obo/OBA_0000056
      def scan_query(options = {})
        limit = options[:limit] || 100
        offset = options[:offset]
        clade = options[:clade]
        query = "# data_search part 1\n"
        fields = "DISTINCT ?page ?trait"
        fields = "COUNT(#{fields})" if options[:count]
        query += "SELECT #{fields} WHERE { "\
          "GRAPH <http://eol.org/traitbank> { "\
          "?page a eol:page . "\
          "?page <#{options[:attribute]}> ?trait . "
        if clade
          query += "?page eol:has_ancestor <http://eol.org/pages/#{clade}> . "
        end
        # TODO: This ORDER BY only really works if numeric! :S
        query += "?trait a eol:trait . "\
          "?trait dwc:measurementValue ?value . } } "\
          "ORDER BY xsd:float(REPLACE(?value, \",\", \"\")) "\
          "LIMIT #{limit} "\
          "#{"OFFSET #{offset}" if offset}"
      end

      def trait_count(options)
        TraitBank.connection.query(scan_query(options.merge(count: true)))
      end

      def trait_list(options)
        TraitBank.connection.query(scan_query(options))
      end

      def metadata(traits)
        trait_strings = traits.map { |r| r[:trait].to_s }
        query = "SELECT DISTINCT *
        # data_search part 2
        WHERE {
          GRAPH <http://eol.org/traitbank> {
            ?trait a eol:trait .
            ?trait ?trait_predicate ?value .
            OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
            FILTER ( ?trait IN (<#{trait_strings.join(">, <")}>) )
          }
        }
        ORDER BY ?trait"
        trait_data = TraitBank.connection.query(query)
        trait_data.each do |td|
          td[:page] = traits.find { |t| t[:trait] == td[:trait] }[:page]
        end
        trait_data
      end
    end
  end
end
