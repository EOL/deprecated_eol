module EOL
  module Sparql
    class ImportUsers < EOL::Sparql::Importer

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://eol.org/users/"
      end

      def begin
        min_id = User.minimum(:id) || 0
        max_id = User.maximum(:id) || 0

        sparql_client.delete_graph(graph_name)
        iteration_size = 100000
        start = min_id
        data = []
        total_lines_inserted = 0
        until start > max_id
          results = User.connection.execute("
            SELECT u.id, u.username, u.given_name, u.family_name, cl.label, u.active, l.iso_639_1
            FROM users u
            LEFT JOIN languages l ON (u.language_id=l.id)
            LEFT JOIN curator_levels cl ON (u.curator_level_id=cl.id)
            WHERE u.id BETWEEN #{start} AND #{start + iteration_size - 1}")
          results.each do |result|
            user_id = result[0]
            username = result[1]
            given_name = result[2]
            family_name = result[3]
            curator_level_label = result[4]
            active = result[5]
            language_iso = result[6]

            data_line = "<http://eol.org/users/#{user_id}> a foaf:Person"
            data_line += "; foaf:firstName \"#{EOL::Sparql.convert(given_name)}\"" unless given_name.blank?
            data_line += "; foaf:familyName \"#{EOL::Sparql.convert(family_name)}\"" unless family_name.blank?
            data_line += "; dc:language \"#{EOL::Sparql.convert(language_iso)}\"" unless language_iso.blank?
            data_line += "; eol:curatorLevel eol:#{curator_level_label.tr(' ','').camelize(:lower)}" unless curator_level_label.blank?
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