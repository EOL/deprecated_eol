# NOTE - this is a little odd. It's got its own little set of SPARQL-writing functions, which really should be generalized and made available in the other
# classes that might want to call SPARQL. That said, these methods could be better-generalized, too.
module EOL
  module Sparql
    class SearchQueryBuilder

      def initialize(options)
        # TODO - this is neat and all, but lacks transparency, since we don't
        # know what options are available to .prepare_search_query. So, this
        # should be a list of variables.
        options.each { |k,v| instance_variable_set("@#{k}", v) }
        @per_page ||= 30
        @page ||= 1
        @only_count = true if @count_value_uris
        @offset ||= 0
      end

      # Class method to build a query
      # This is likely the only thing that will get called outside this class
      #
      # NOTE - options are (currently) every single instance variable you see
      # in this class. (TODO - clarify)
      def self.prepare_search_query(options)
        builder = EOL::Sparql::SearchQueryBuilder.new(options)
        builder.prepare_query
      end

      # TODO - this is only used in this lib, so could be a private method
      # (but class methods cannot be private, soooo... decide what to do.)
      #
      # Basic query assembler
      def self.build_query(select, where, order, limit)
        "#{ select } WHERE {
            #{ where }
          }
          #{ order ? order : '' }
          #{ limit ? limit : '' }"
      end

      # To add a taxon filter, the current best way is to do a UNION of the results
      # of data for a taxon, and results for the descendants of the taxon - not
      # doing some kind of conditional
      def self.build_query_with_taxon_filter(taxon_concept_id, select, where, order)
        "{
          #{ select } WHERE {
            #{ where }
            ?parent_taxon dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept_id}> .
            ?parent_taxon dwc:taxonConceptID ?parent_taxon_concept_id .
            ?t dwc:parentNameUsageID+ ?parent_taxon .
            ?t dwc:taxonConceptID ?taxon_concept_id
          }
          #{ order ? order : '' }
        } UNION {
          #{ select } WHERE {
            #{ where }
            ?taxon_id dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept_id}>
          }
          #{ order ? order : '' }
        }"
      end

      # Instance method to put together all the pieces and return a string
      # representing the final Sparql search query
      def prepare_query
        if @taxon_concept
          inner_query = EOL::Sparql::SearchQueryBuilder.build_query_with_taxon_filter(@taxon_concept.id, inner_select_clause, where_clause, inner_order_clause)
        else
          inner_query = EOL::Sparql::SearchQueryBuilder.build_query(inner_select_clause, where_clause, inner_order_clause, nil)
        end
        # this is strange, but in order to properly do sorts, limits, and offsets there should be a subquery
        # see http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtTipsAndTricksHowToHandleBandwidthLimitExceed
        EOL::Sparql::SearchQueryBuilder.build_query(outer_select_clause, inner_query, outer_order_clause, limit_clause)
      end

      def where_clause
        "GRAPH ?graph {
            ?data_point_uri dwc:measurementType ?attribute .
            {#{ attribute_filter } }
            #{union_attributes}
          } .
          ?data_point_uri dwc:measurementValue ?value .
          ?data_point_uri eol:measurementOfTaxon eolterms:true .
          ?data_point_uri dwc:occurrenceID ?occurrence_id .
          ?occurrence_id dwc:taxonID ?taxon_id .
          ?taxon_id dwc:taxonConceptID ?taxon_concept_id .
          OPTIONAL { ?occurrence_id dwc:lifeStage ?life_stage } .
          OPTIONAL { ?occurrence_id dwc:sex ?sex } .
          OPTIONAL { ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri } .
          OPTIONAL { ?data_point_uri eolterms:statisticalMethod ?statistical_method } .
          #{ filter_clauses }"
      end

      def outer_select_clause
        if @count_value_uris
          "SELECT ?value, COUNT(*) as ?count"
        elsif @only_count
          "SELECT COUNT(*) as ?count"
        else
          "SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri ?statistical_method ?life_stage ?sex ?data_point_uri ?graph ?taxon_concept_id"
        end
      end

      def inner_select_clause
        if @count_value_uris
          "SELECT DISTINCT ?data_point_uri, ?value"
        elsif @only_count
          "SELECT DISTINCT ?data_point_uri"
        else
          "SELECT ?attribute ?value ?unit_of_measure_uri ?statistical_method ?life_stage ?sex ?data_point_uri ?graph ?taxon_concept_id"
        end
      end

      def filter_clauses
        filter_clauses = ""
        # numerical range search with units
        if @unit && (@min_value || @max_value)
          builder = EOL::Sparql::UnitQueryBuilder.new(@unit, @min_value, @max_value)
          filter_clauses += builder.sparql_query_filters
        # numerical range search term
        elsif @min_value || @max_value
          filter_clauses += "FILTER(xsd:float(?value) >= xsd:float(#{ @min_value })) . " if @min_value
          filter_clauses += "FILTER(xsd:float(?value) <= xsd:float(#{ @max_value })) . " if @max_value
        # exact numerical search term
        elsif @querystring && @querystring.is_numeric?
          filter_clauses += "FILTER(xsd:float(?value) = xsd:float(#{ @querystring })) . "
        # string search term
        elsif @querystring && ! @querystring.strip.empty?
          filter_clauses += "FILTER("
          f = filter_values(@querystring)
          if @required_equivalent_values
            @required_equivalent_values.each do |req|
              q = KnownUri.find(req.to_i).name
              f += " || #{filter_values(q)}"
            end
          end
          filter_clauses += f
          filter_clauses += " ) . "
        end
        if @count_value_uris
          filter_clauses += "FILTER(isURI(?value)) . "
        end
        filter_clauses
      end

      def filter_values(querystring)
        filter_clauses = ""
        matching_known_uris = KnownUri.search(querystring)
        filter_clauses += "( REGEX(?value, '(^|\\\\W)#{ querystring }(\\\\W|$)', 'i'))"
        unless Array(matching_known_uris).empty?
          filter_clauses << " || ?value IN (<#{ matching_known_uris.collect(&:uri).join('>,<') }>)"
        end
        filter_clauses
      end

      def limit_clause
        @only_count ? "" : "LIMIT #{ @per_page } OFFSET #{ (((@page.to_i - 1) * @per_page) + @offset) }"
      end

      def inner_order_clause
        unless @only_count
          if @sort == 'asc'
            return "ORDER BY ASC(xsd:float(?value)) ASC(?value)"
          elsif @sort == 'desc'
            return "ORDER BY DESC(xsd:float(?value)) DESC(?value)"
          end
        end
        ""
      end

      def outer_order_clause
        if @count_value_uris
          return "GROUP BY ?value ORDER BY DESC(?count)"
        end
        ""
      end

      def attribute_filter
        @attribute ? "?data_point_uri dwc:measurementType <#{ @attribute }> ." : ""
      end

      def union_attributes
        attrs = ""
        if @required_equivalent_attributes
          @required_equivalent_attributes.each do |req|
            attrs += " union { ?data_point_uri dwc:measurementType <#{KnownUri.find(req.to_i).uri}> . } "
          end
        end
        attrs
      end

      def union_values
        attrs = ""
        if @required_equivalent_values
          @required_equivalent_values.each do |req|
            attrs += " union { ?data_point_uri dwc:measurementType <#{KnownUri.find(req.to_i).uri}> . } "
          end
        end
        attrs
      end

    end
  end
end
