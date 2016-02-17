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
      #   unit: @unit, sort: @sort, language: current_language,
      #   taxon_concept: @taxon_concept,
      #   required_equivalent_attributes: @required_equivalent_attributes,
      #   required_equivalent_values: @required_equivalent_values }
      # TODO: someday we might want to pass in a page size
      def connection
       @conneciton ||= EOL::Sparql.connection
      end

      def for(options)
        traits = TraitBank.connection.query(scan_query(options))
        metadata(traits)
      end

      def trait_count(options)
        TraitBank.connection.
          query(scan_query(options.merge(count: true))).
          first[:"callret-0"].to_i
      end

      # NOTE: PREFIX eol: <http://eol.org/schema/>
      # PREFIX dwc: <http://rs.tdwg.org/dwc/terms/>
      # e.g.: http://purl.obolibrary.org/obo/OBA_0000056
      def scan_query(options = {})
        size = options[:per_page] || 100
        # This check is because you will lose results if the total number of
        # rows returned (each line of metadata) exceeds 10,000--an internal
        # limit of Virtuoso. Pages of 1000 almost never work, 800 MIGHT work...
        # 500 is MOSTLY safe, but still risky... but I'll allow it as a max:
        raise "Query page size limit exceeded!" if size > 500
        offset = ((options[:page] || 1) - 1) * size
        clade = options[:clade]
        query = "# data_search #{options[:count] ? "(count)" : "part 1"}\n"
        fields = "DISTINCT ?page ?trait"
        fields = "COUNT(*)" if options[:count]
        query += "SELECT #{fields} WHERE { "\
          "GRAPH <http://eol.org/traitbank> { "\
          "?page a eol:page . "\
          "?page <#{options[:attribute]}> ?trait . "
        if clade
          query += "?page eol:has_ancestor <http://eol.org/pages/#{clade}> . "
        end
        query += "?trait a eol:trait . "\
          "?trait dwc:measurementValue ?value . } } "
        # TODO: This ORDER BY only really works if numeric! :S
        unless options[:count]
          # TODO: figure out how to sort properly, both numerically and alpha.
          orders = ["xsd:float(?value)", "?value"]
          orders.map! { |ord| "DESC(#{ord})" } if options[:sort] =~ /^desc$/i
          query += "ORDER BY #{orders.join(" ")} "
          if offset && offset > 0
            query = scrollable_cursor(query, size, offset)
          else
            query += "LIMIT #{size} "
          end
        end
        # NOTE: If you're experiencing Virtuoso problems, this is handy:
        # EOL.log(query, prefix: "Q")
        query
      end

      def scrollable_cursor(query, limit, offset)
        "SELECT * WHERE { { #{query} } } LIMIT #{limit} OFFSET #{offset}"
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
        ORDER BY DESC(xsd:float(?value)) DESC(?value)"
        trait_data = TraitBank.connection.query(query)
        if trait_data.count >= 10_000
          EOL.log("WARNING! The following query reached a limit in the number "\
            "of rows returned by Virtuoso (#{trait_data.count}):", prefix: "!")
          EOL.log(query, prefix: "!")
        end
        trait_data.each do |td|
          td[:page] = traits.find { |t| t[:trait] == td[:trait] }[:page]
        end
        trait_data
      end
    end
  end
end
