class TaxonDetails < TaxonUserClassificationFilter

  # TODO - break down into friendlier syntax. :)
  def get_data
    rows = data
    rows.each do |row|
      if user = get_user(row[:user_added_data_id])
        row[:user] = user
      end
    end
  end

  private

  def get_user(value)
    if value && matches = value.to_s.match(/\/([0-9])$/)
      uad = UserAddedData.find(matches[1])
      return uad.user if uad
    end
    nil
  end

  def data
    EOL::Sparql.connection.query(%(
      SELECT DISTINCT ?attribute ?value ?user_added_data_id
      FROM <#{UserAddedData::GRAPH_NAME}>
      WHERE { ?user_added_data_id <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/pages/#{taxon_concept.id}> .
        ?user_added_data_id <http://rs.tdwg.org/dwc/terms/measurementType> ?attribute .
        ?user_added_data_id <http://rs.tdwg.org/dwc/terms/measurementValue> ?value }
      ORDER BY ?attribute
    )) +
    EOL::Sparql.connection.query(%(
      SELECT DISTINCT ?attribute ?value ?graph
         GRAPH <http://eol.org/taxon_mappings/> {
            ?taxon <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/pages/#{taxon_concept.id}> .
          } .
          GRAPH ?graph {
            ?taxon ?attribute ?value
            FILTER (?graph != <http://eol.org/taxon_mappings/> AND ?graph != <#{UserAddedData::GRAPH_NAME}>)
            FILTER (?attribute NOT IN (<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>,
              <http://eol.org/schema/terms/canonical>))
          }
        }
     ))
  end

end
