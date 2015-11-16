class TraitBank
  class << self
    # Stupid that this is hidden as much as it is:
    def prefixes
      EOL::Sparql.connection.send :namespaces_prefixes
    end

    def fix_old_data
      graph_name = "http://eol.org/traitbank"
      EOL::Sparql.connection.query(
        "WITH <#{graph_name}> DELETE { ?s ?p ?o . } WHERE { ?s ?p ?o . }")
      triples = []
      limit = 10 # TODO: change
      query = "#{prefixes}
        SELECT DISTINCT ?predicate ?value ?units
          ?statistical_method ?life_stage ?sex ?taxon ?trait ?resource
          ?page
        WHERE {
          GRAPH ?resource {
            ?trait dwc:measurementType ?predicate .
            ?trait dwc:measurementValue ?value .
            OPTIONAL { ?trait dwc:measurementUnit ?units } .
            OPTIONAL { ?trait eolterms:statisticalMethod ?statistical_method } .
          } .
          {
            ?trait dwc:taxonConceptID ?page .
            OPTIONAL { ?trait dwc:lifeStage ?life_stage } .
            OPTIONAL { ?trait dwc:sex ?sex }
          }
          UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?trait eol:measurementOfTaxon eolterms:true .
            GRAPH ?resource_mappings_graph {
              ?taxon dwc:taxonConceptID ?page
            }
            OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } .
            OPTIONAL { ?occurrence dwc:sex ?sex }
          }
        }
        LIMIT #{limit}"
      puts "QUERY:"
      puts query
      puts "---"
      EOL::Sparql.connection.query(query).each do |h|
        raise "No value for #{h[:trait]}!" unless h[:value]
        triples << "<#{h[:page]}> a <http://eol.org/schema/page> ; "\
          "<#{h[:predicate]}> <#{h[:trait]}>"
        add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/measurementValue",
          :value, literal: true)
        add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/measurementUnit",
          :units)
        add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/sex",
          :sex)
        add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/lifeStage",
          :life_stage)
        add_meta(triples, h, "http://eol.org/schema/terms/statisticalMethod",
          :statistical_method)
        add_meta(triples, h, "source", :resource)
      end
      EOL::Sparql.connection.insert_data(data: triples, graph_name: graph_name)
      puts triples[0..12].join("\n")
    end

    def add_meta(triples, h, uri, key, options = {})
      puts "checking #{key} from #{h.keys.join(",")}"
      return if h[key].nil?
      triple = "<#{h[:trait]}> <#{uri}> "
      if options[:literal]
        triple << "\"#{h[key]}\""
      else
        triple << "<#{h[key]}>"
      end
      puts "Adding: #{triple}"
      triples << triple
    end

    def see_results
      query = "
      SELECT DISTINCT ?page ?predicate ?trait ?meta_predicate ?meta_value
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?page a eol:page .
          ?page ?predicate ?trait .
          ?trait ?meta_predicate ?meta_value .
        }
      }
      LIMIT 20
      "
      pp EOL::Sparql.connection.query(query)
    end
  end
end
