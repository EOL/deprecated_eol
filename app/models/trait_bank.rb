class TraitBank
  class << self
    # Stupid that this is hidden as much as it is:
    def prefixes
      EOL::Sparql.connection.send :namespaces_prefixes
    end

    def graph_name
      "http://eol.org/traitbank"
    end

    # TODO: We need to scale this up! It's not ready to handle Multiple
    # resources with millions of rows, yet...
    def study_traits
      # TODO: we don't actually want to nuke the graph when we do this, we want
      # to build a new one and replace the old. ...Not sure how best to do that,
      # though.
      EOL::Sparql.connection.query("CLEAR GRAPH <#{graph_name}>")
      triples = []
      taxa = Set.new
      taxon_re = /^.*\/(\d+)$/
      traits = Set.new
      limit = 6400
      EOL::Sparql.connection.query(measurements_query(limit)).each do |h|
        raise "No value for #{h[:trait]}!" unless h[:value]
        taxa << h[:page].to_s.sub(taxon_re, "\\1")
        triples << "<#{h[:page]}> a eol:page ; "\
          "<#{h[:predicate]}> <#{h[:trait]}>"
        triples << "<#{h[:trait]}> a eol:trait"
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
        traits << h[:trait]
      end
      EOL::Sparql.connection.query(associations_query(limit)).each do |h|
        triples << "<#{h[:page]}> a <http://eol.org/schema/page> ;"\
          "<#{h[:predicate]}> <#{h[:target_page]}> ;"\
          "<source> <#{h[:resource]}>"
        triples << "<#{h[:target_page]}> a <http://eol.org/schema/page> ;"\
          "<#{h[:inverse]}> <#{h[:page]}> ;"\
          "<source> <#{h[:resource]}>"
        traits << h[:trait]
      end
      # ?trait ?predicate ?meta_trait ?value ?units
      EOL::Sparql.connection.query(metadata_query(traits, limit)).each do |h|
        if h[:units].blank?
          add_meta(triples, h, h[:predicate], :value, literal: h[:value].literal?)
        else
          triples << "<#{h[:trait]}> <#{h[:predicate]}> <#{h[:meta_trait]}> ."
          val = h[:value].literal? ? "\"#{h[:value]}\"" : "<#{h[:value]}>"
          triples << "<#{h[:meta_trait]}> a eol:trait ;"\
            "<http://rs.tdwg.org/dwc/terms/measurementValue> #{val} ;"\
            "<http://rs.tdwg.org/dwc/terms/measurementUnit> <#{h[:units]}>"
        end
      end
      EOL::Sparql.connection.insert_data(data: triples, graph_name: graph_name)
      flatten_taxa(taxa)
    end

    def flatten_taxa(taxa)
      EOL.log_call
      taxa.to_a.in_groups_of(640, false) do |group|
        triples = []
        TaxonConceptsFlattened.where(taxon_concept_id: group).
          find_each do |flat|
          # Note the *ancestor* might not be a page yet: (often isn't!)
          triples << "<http://eol.org/pages/#{flat.ancestor_id}> a eol:page"
          triples << "<http://eol.org/pages/#{flat.taxon_concept_id}> "\
            "eol:has_ancestor <http://eol.org/pages/#{flat.ancestor_id}>"
        end
        EOL::Sparql.connection.insert_data(data: triples,
          graph_name: graph_name)
      end
    end

    def add_meta(triples, h, uri, key, options = {})
      return if h[key].nil?
      triple = "<#{h[:trait]}> <#{uri}> "
      if options[:literal]
        triple << "\"#{h[key]}\""
      else
        triple << "<#{h[key]}>"
      end
      triples << triple
    end

    def pages(limit = 1000, offset = nil)
      query = "
      SELECT DISTINCT *
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?page a eol:page
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query).map do |r|
        r[:page].to_s.sub(/.*\/(\d+)$/, '\1')
      end
    end

    def traits_for_page(page, limit = 1000, offset)
      query = "
      SELECT DISTINCT *
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          <http://eol.org/pages/#{page}> ?predicate ?trait .
          ?trait a eol:trait .
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    # Given a page, get all of its traits and all of its metadata. Note that
    # this necessarily returns a bunch of predicates of
    # <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, which you should
    # ignore. Sorry!
    def page_with_traits(page, limit = 1000, offset = nil)
      query = "
      SELECT DISTINCT *
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          <http://eol.org/pages/#{page}> ?predicate ?trait .
          ?trait a eol:trait .
          ?trait ?trait_predicate ?value .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    # e.g.: http://purl.obolibrary.org/obo/OBA_1000036 on http://eol.org/pages/41
    def data_search(predicate, limit = 1000, offset = nil)
      query = "
      SELECT DISTINCT *
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
      EOL::Sparql.connection.query(query)
    end

    # NOTE: I copy/pasted this. TODO: generalize. 37 should include 41, and NOT include 904.
    def data_search_within_clade(predicate, clade, limit = 1000, offset = nil)
      query = "
      SELECT DISTINCT *
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
      EOL::Sparql.connection.query(query)
    end

    # Given a list of traits, get all the metadata for them:
    def get_traits(traits, limit = 1000, offset = nil)
      query = "
      SELECT DISTINCT *
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?trait ?predicate ?value .
          ?trait a eol:trait .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
          FILTER (?trait IN (<#{traits.map(&:to_s).join('>,<')}>))
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    def measurements_query(limit = 640, offset = nil)
      "#{prefixes}
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
        LIMIT #{limit}
        #{"OFFSET #{offset}" if offset}"
    end

    def associations_query(limit = 640, offset = nil)
      "#{prefixes}
        SELECT DISTINCT ?page ?predicate ?target_page
          ?inverse ?trait ?resource
        WHERE {
          GRAPH ?resource_mappings_graph {
            ?taxon dwc:taxonConceptID ?page .
            ?value dwc:taxonConceptID ?target_page
          } .
          GRAPH ?resource {
            ?occurrence dwc:taxonID ?taxon .
            ?target_occurrence dwc:taxonID ?value .
            {
              ?trait dwc:occurrenceID ?occurrence .
              ?trait eol:targetOccurrenceID ?target_occurrence .
              ?trait eol:associationType ?predicate
            }
            UNION
            {
              ?trait dwc:occurrenceID ?target_occurrence .
              ?trait eol:targetOccurrenceID ?occurrence .
              ?trait eol:associationType ?inverse
            }
          } .
          OPTIONAL {
            GRAPH ?mappings {
              ?inverse owl:inverseOf ?predicate
            }
          }
        }
        LIMIT #{limit}
        #{"OFFSET #{offset}" if offset}"
    end

    def metadata_query(traits, limit, offset = 0)
      left = offset ? 0 : offset
      right = (offset + limit) - 1
      right = traits.count - 1 if traits.count - 1 > right
      "#{prefixes}
      SELECT DISTINCT ?trait ?predicate ?meta_trait ?value ?units
      WHERE {
        GRAPH ?graph {
          {
            ?trait ?predicate ?value .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence ?predicate ?value .
          } UNION {
            ?meta_trait eol:parentMeasurementID ?trait .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?meta_trait dwc:occurrenceID ?occurrence .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            FILTER NOT EXISTS { ?meta_trait eol:measurementOfTaxon eolterms:true } .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?meta_trait eol:associationID ?trait .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:eventID ?event .
            ?event ?predicate ?value .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?taxon ?predicate ?value .
            FILTER (?predicate = dwc:scientificName)
          }
          FILTER (?predicate NOT IN (rdf:type, dwc:taxonConceptID, dwc:measurementType, dwc:measurementValue,
                                     dwc:measurementID, eolreference:referenceID,
                                     eol:targetOccurrenceID, dwc:taxonID, dwc:eventID,
                                     eol:associationType,
                                     dwc:measurementUnit, dwc:occurrenceID, eol:measurementOfTaxon)
                  ) .
          FILTER (?trait IN (<#{traits.to_a[left..right].join('>,<')}>))
        }
      }"
    end
  end
end
