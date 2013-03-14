module EOL
  module Sparql
    class ExportCol

      def self.as_rdf_xml
        export(:rdf_xml)
      end

      def self.as_turtle
        export(:turtle)
      end

      def self.export(format)
        min_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).minimum('hierarchy_entries.id') || 0
        max_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).maximum('hierarchy_entries.id') || 0

        iteration_size = 100000
        start = min_id
        filename = (format == :turtle) ? 'col.ttl' : 'col.rdf'
        filepath = File.join(Rails.root, 'tmp', filename)
        f = File.new(filepath, 'w+')
        f.write(header(format))
        until start > max_id
          results = HierarchyEntry.connection.execute("
            SELECT he.id, he.parent_id, he.taxon_concept_id, n.string, tr.label, cf.string
            FROM hierarchy_entries he
            LEFT JOIN names n ON (he.name_id=n.id)
            LEFT JOIN ( ranks r JOIN translated_ranks tr ON (r.id=tr.rank_id AND tr.language_id=#{Language.default.id}) ) ON he.rank_id=r.id
            LEFT JOIN canonical_forms cf ON (n.canonical_form_id=cf.id)
            WHERE he.hierarchy_id=#{Hierarchy.col.id} AND he.id BETWEEN #{start} AND #{start + iteration_size - 1}")
          results.each do |result|
            if format == :rdf_xml
              f.write(prepare_xml(result) + "\n")
            elsif format == :turtle
              f.write(prepare_turtle(result) + "\n")
            end
          end
          start += iteration_size
        end
        f.write("</rdf:RDF>") if format == :rdf_xml
        f.close
      end

      def self.prepare_xml(result)
        hierarchy_entry_id = result[0]
        parent_id = result[1]
        taxon_concept_id = result[2]
        name_string = result[3]
        rank_label = result[4]
        canonical_form = result[5]
        xml = "<rdf:Description rdf:about=\"http://eol.org/hierarchy_entries/#{hierarchy_entry_id}\">\n"
        xml += "  <rdf:type rdf:resource=\"http://rs.tdwg.org/dwc/terms/Taxon\" />\n"
        xml += "  <dwc:scientificName>#{EOL::Sparql.convert(name_string)}</dwc:scientificName>\n"
        xml += "  <dwc:taxonConceptID rdf:resource=\"http://eol.org/pages/#{taxon_concept_id}\" />\n"
        xml += "  <dwc:taxonRank rdf:resource=\"http://eol.org/ranks/#{EOL::Sparql.to_underscore(rank_label)}\" />\n" unless rank_label.blank?
        xml += "  <eol:canonical rdf:resource=\"http://eol.org/canonical_forms/#{EOL::Sparql.to_underscore(canonical_form)}\" />\n" unless canonical_form.blank?
        if parent_id.blank? || parent_id == 0
          xml += "  <dwc:parentNameUsageID rdf:resource=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#:nil\" />\n"
        else
          xml += "  <dwc:parentNameUsageID rdf:resource=\"http://eol.org/hierarchy_entries/#{parent_id}\" />\n"
        end
        xml += "</rdf:Description>\n"
        return xml
      end

      def self.prepare_turtle(result)
        hierarchy_entry_id = result[0]
        parent_id = result[1]
        taxon_concept_id = result[2]
        name_string = result[3]
        rank_label = result[4]
        canonical_form = result[5]
        tuples = "<http://eol.org/hierarchy_entries/#{hierarchy_entry_id}> a dwct:Taxon\n"
        tuples += "  ; dwc:scientificName \"#{EOL::Sparql.convert(name_string)}\"\n"
        tuples += "  ; dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept_id}>\n"
        tuples += "  ; dwc:taxonRank <http://eol.org/ranks/#{EOL::Sparql.to_underscore(rank_label)}>\n" unless rank_label.blank?
        tuples += "  ; eol:canonical <http://eol.org/canonical_forms/#{EOL::Sparql.to_underscore(canonical_form)}>\n" unless canonical_form.blank?
        if parent_id.blank? || parent_id == 0
          tuples += "  ; dwc:parentNameUsageID <http://www.w3.org/1999/02/22-rdf-syntax-ns#:nil>\n"
        else
          tuples += "  ; dwc:parentNameUsageID <http://eol.org/hierarchy_entries/#{parent_id}>\n"
        end
        return tuples
      end

      def self.header(format)
        namespaces = EOL::Sparql.common_namespaces
        if format == :rdf_xml
          "<rdf:RDF\n  " +
          namespaces.collect{ |ns,uri| "xmlns:#{ns}=\"#{uri}\"" }.join("\n  ") + ">\n\n"
        elsif format == :turtle
          namespaces.collect{ |ns,uri| "@prefix #{ns}: <#{uri}>" }.join(" .\n") + " .\n\n"
        end
      end

    end
  end
end