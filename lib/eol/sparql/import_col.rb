module EOL
  module Sparql
    class ImportCol < EOL::Sparql::Importer

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://col/"
      end

      def begin
        min_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).minimum('hierarchy_entries.id') || 0
        max_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).maximum('hierarchy_entries.id') || 0

        sparql_client.delete_graph(graph_name)
        iteration_size = 100000
        start = min_id
        data = []
        total_lines_inserted = 0
        until start > max_id
          results = HierarchyEntry.connection.execute("
            SELECT he.id, he.parent_id, he.taxon_concept_id, n.string, tr.label, cf.string
            FROM hierarchy_entries he
            LEFT JOIN names n ON (he.name_id=n.id)
            LEFT JOIN ( ranks r JOIN translated_ranks tr ON (r.id=tr.rank_id AND tr.language_id=#{Language.default.id}) ) ON he.rank_id=r.id
            LEFT JOIN canonical_forms cf ON (n.canonical_form_id=cf.id)
            WHERE he.hierarchy_id=#{Hierarchy.col.id} AND he.id BETWEEN #{start} AND #{start + iteration_size - 1}")
          results.each do |result|
            hierarchy_entry_id = result[0]
            parent_id = result[1]
            taxon_concept_id = result[2]
            name_string = result[3]
            rank_label = result[4]
            canonical_form = result[5]

            data_line = "<http://eol.org/hierarchy_entries/#{hierarchy_entry_id}> a dwct:Taxon"
            data_line += "; dwc:scientificName \"#{EOL::Sparql.convert(name_string)}\""
            data_line += "; dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept_id}>"
            data_line += "; dwc:taxonRank <http://eol.org/ranks/#{EOL::Sparql.to_underscore(rank_label)}>" unless rank_label.blank?
            data_line += "; eol:canonical <http://eol.org/canonical_forms/#{EOL::Sparql.to_underscore(canonical_form)}>" unless canonical_form.blank?
            if parent_id.blank? || parent_id == 0
              data_line += "; dwc:parentNameUsageID <http://www.w3.org/1999/02/22-rdf-syntax-ns#:nil>"
            else
              data_line += "; dwc:parentNameUsageID <http://eol.org/hierarchy_entries/#{parent_id}>"
            end
            data << data_line
            if data.length >= 10000
              puts "Inserting lines #{total_lines_inserted} to #{total_lines_inserted + data.length}..."
              total_lines_inserted += data.length
              sparql_client.insert_data(:data => data, :graph_name => graph_name)
              data = []
            end
          end
          start += iteration_size
        end
        puts "Inserting lines #{total_lines_inserted} to #{total_lines_inserted + data.length}..."
        total_lines_inserted += data.length
        sparql_client.insert_data(:data => data, :graph_name => graph_name)
      end

    end
  end
end