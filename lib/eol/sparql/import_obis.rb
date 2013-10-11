module EOL
  module Sparql
    class ImportObis < EOL::Sparql::Importer

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://obis/"
      end

      def begin
        require 'csv'
        sparql_client.delete_graph(graph_name)
        lines = 0
        fields_by_column_number = {}
        column_number_by_field_name = {}
        fields_to_ingest = [ 'minlat', 'maxlat', 'minlon', 'maxlon', 'minbotdepth', 'maxbotdepth', 'mindepth', 'maxdepth',
                             'minwoadepth', 'maxwoadepth', 'minaou', 'maxaou', 'minnitrate', 'maxnitrate', 'mino2sat', 'maxo2sat',
                             'minoxygen', 'maxoxygen', 'minphosphate', 'maxphosphate', 'minsalinity', 'maxsalinity',
                             'minsilicate', 'maxsilicate', 'mintemperature', 'maxtemperature' ]
        data = []
        total_lines_inserted = 0
        CSV.foreach("/Users/pleary/Downloads/OBIS_data.csv") do |row|
          lines += 1
          if lines == 1
            row.each_with_index do |value, index|
              fields_by_column_number[index] = value
              column_number_by_field_name[value] = index
            end
            next
          end

          obis_id = row[column_number_by_field_name['id']]
          canonical = row[column_number_by_field_name['tname']].strip
          canonical.gsub!(/ \(.+?\)/, '')
          canonical.gsub!(/ (var|f|cf|aff|sub|unspec|of|trans|subsp|sp|n|mac|v|re)\./, '')
          next if canonical.blank? || canonical =~ /[^a-z -]/i
          canonical = EOL::Sparql.to_underscore(canonical)

          data_line = "<http://iobis.org/taxa/#{obis_id}> a dwct:Taxon";
          data_line += "; eol:canonical <http://eol.org/canonical_forms/#{canonical}>"
          fields_to_ingest.each do |field_name|
            value = row[column_number_by_field_name[field_name]]
            unless value.blank?
              data_line += "; obis:#{field_name} #{EOL::Sparql.convert(value)}"
            end
          end

          data << data_line
          if data.length >= 3000
            puts "Inserting lines #{total_lines_inserted} to #{total_lines_inserted + data.length}..."
            total_lines_inserted += data.length
            sparql_client.insert_data(:data => data, :graph_name => graph_name)
            data = []
          end
        end
        puts "Inserting lines #{total_lines_inserted} to #{total_lines_inserted + data.length}..."
        total_lines_inserted += data.length
        sparql_client.insert_data(:data => data, :graph_name => graph_name)
      end

    end
  end
end