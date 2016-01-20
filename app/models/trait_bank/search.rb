class TraitBank
  class Search
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
        if search[:taxon_concept]
          if search[:querystring]
            raise "Not yet"
          else
            data_search_within_clade(search[:attribute],
              search[:taxon_concept].id)
          end
        else
          if search[:querystring]
            raise "Not yet"
          else
            data_search_predicate(search[:attribute])
          end
        end
      end

      # e.g.: http://purl.obolibrary.org/obo/OBA_1000036 on http://eol.org/pages/41
      def data_search_predicate(predicate, limit = 100, offset = nil)
        query = "SELECT DISTINCT *
        # data_search
        WHERE {
          GRAPH <http://eol.org/traitbank> {
            ?page <#{predicate}> ?trait .
            ?trait a eol:trait .
            ?trait ?trait_predicate ?value .
            OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
          }
        }
        LIMIT #{limit}
        #{"OFFSET #{offset}" if offset}"
        connection.query(query)
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
        LIMIT #{limit}
        #{"OFFSET #{offset}" if offset}"
        connection.query(query)
      end
    end
  end
end
