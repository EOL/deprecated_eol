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
        predicate = search.delete(:attribute)
        clade = search.delete(:taxon_concept).try(:id)
        options = { limit: 100, clade: clade }.merge(search)
        traits = get_trait_list(predicate, clade: clade, options)
        results = get_metadata(predicate, traits)
        WillPaginate::Collection.create(search[:page] ||
          1, 100, 1_000_000) do |pager|
          pager.replace results
        end
      end

      # NOTE: PREFIX eol: <http://eol.org/schema/>
      # PREFIX dwc: <http://rs.tdwg.org/dwc/terms/>
      # e.g.: http://purl.obolibrary.org/obo/OBA_0000056
      def get_trait_list(predicate, options = {})
        limit = options[:limit]
        offset = options[:offset]
        clade = options[:clade]
        query = "# data_search part 1\n"\
          "SELECT DISTINCT ?trait "\
          "WHERE { "\
          "  GRAPH <http://eol.org/traitbank> { "\
          "    ?page a eol:page . "\
          "    ?page <#{predicate}> ?trait . "
        if clade
          query += "  ?page eol:has_ancestor <http://eol.org/pages/#{clade}> . "
        end
        query += "?trait a eol:trait . "\
          "    ?trait dwc:measurementValue ?value . "\
          "  } "\
          "} "\
          "ORDER BY xsd:float(?value) "\ # TODO: only really works if numeric! :S
          "LIMIT #{limit} "\
          "#{"OFFSET #{offset}" if offset}"
        TraitBank.connection.query(query).map { |r| r[:trait].to_s }
      end

      def get_metadata(predicate, traits)
        query = "SELECT DISTINCT *
        # data_search part 2
        WHERE {
          GRAPH <http://eol.org/traitbank> {
            ?page a eol:page .
            ?page <#{predicate}> ?trait .
            ?trait a eol:trait .
            ?trait ?trait_predicate ?value .
            OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
            FILTER ( ?trait IN (<#{traits.join(">, <")}>) )
          }
        }
        ORDER BY ?trait"
        TraitBank.connection.query(query)
      end
    end
  end
end
