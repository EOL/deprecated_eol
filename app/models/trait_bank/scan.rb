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
      # - pagination
      #
      # { querystring: @querystring, attribute: @attribute,
      #   min_value: @min_value, max_value: @max_value,
      #   unit: @unit, sort: @sort, language: current_language,
      #   taxon_concept: @taxon_concept,
      #   required_equivalent_attributes: @required_equivalent_attributes,
      #   required_equivalent_values: @required_equivalent_values }
      def for(search)
        if search[:querystring].blank?
          data_search_predicate(search[:attribute],
            clade: search[:taxon_concept].try(:id))
        else
          raise "Not yet"
        end
      end

      # NOTE: PREFIX eol: <http://eol.org/schema/>
      # PREFIX dwc: <http://rs.tdwg.org/dwc/terms/>
      # e.g.: http://purl.obolibrary.org/obo/OBA_0000056
      def data_search_predicate(predicate, options = {})
        limit = options[:limit] || 100
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
          "ORDER BY ?value "\
          "LIMIT #{limit} "\
          "#{"OFFSET #{offset}" if offset}"
        traits = TraitBank.connection.query(query).map { |r| r[:trait].to_s }
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

      # NOTE: I copy/pasted this. TODO: generalize. For testing, 37 should include
      # 41, and NOT include 904.
      def data_search_within_clade(predicate, clade, limit = 100, offset = nil)
        query = "SELECT DISTINCT *
        # data_search_within_clade
        WHERE {
          GRAPH <http://eol.org/traitbank> {
            ?page <#{predicate}> ?trait .
            ?page eol:has_ancestor <http://eol.org/pages/#{clade}> .
            ?trait a eol:trait .
            ?trait ?trait_predicate ?value .
            OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
          }
        }
        ORDER BY ?trait
        LIMIT #{limit}
        #{"OFFSET #{offset}" if offset}"
        TraitBank.connection.query(query)
      end
    end
  end
end
