module EOL
  module Sparql
    class ImportAnage < EOL::Sparql::Importer

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://anage/"
      end

      def begin
        require 'csv'
        sparql_client.delete_graph(graph_name)
        lines = 0
        fields_by_column_number = {}
        column_number_by_field_name = {}
        fields_to_ingest = {
          'Female maturity (days)' => { :uri => 'anage:f_maturity' },
          'Male maturity (days)' => { :uri => 'anage:m_maturity' },
          'Gestation/Incubation (days)' => { :uri => 'anage:gestation' },
          'Weaning (days)' => { :uri => 'anage:weaning' },
          'Litter/Clutch size' => { :uri => 'anage:litter_size' },
          'Litters/Clutches per year' => { :uri => 'anage:litter_frequency' },
          'Inter-litter/Interbirth interval' => { :uri => 'anage:interbirth' },
          'Birth weight (g)' => { :uri => 'anage:birth_weight' },
          'Weaning weight (g)' => { :uri => 'anage:weaning_weight' },
          'Adult weight (g)' => { :uri => 'anage:adult_weight' },
          'Growth rate (1/days)' => { :uri => 'anage:growth_rate' },
          'Maximum longevity (yrs)' => { :uri => 'anage:max_longevity' },
          'Specimen origin' => { :uri => 'anage:origin', :value_prefix => 'http://anage.org/origin/' },
          'Sample size' => { :uri => 'anage:sample_size', :value_prefix => 'http://anage.org/sample_size/' },
          'Data quality' => { :uri => 'anage:quality', :value_prefix => 'http://anage.org/data_quality/' },
          'IMR (per yr)' => { :uri => 'anage:imr' },
          'MRDT (yrs)' => { :uri => 'anage:mrdt' },
          'Metabolic rate (W)' => { :uri => 'anage:metabolic_rate' },
          'Body mass (g)' => { :uri => 'anage:body_mass' },
          'Temperature (K)' => { :uri => 'anage:temperature' }
        }
        data = []
        total_lines_inserted = 0
        CSV.foreach("/Users/pleary/Downloads/dataset/anage_data.txt", { :col_sep => "\t" }) do |row|
          lines += 1
          if lines == 1
            row.each_with_index do |value, index|
              fields_by_column_number[index] = value
              column_number_by_field_name[value] = index
            end
            next
          end

          genus = row[column_number_by_field_name['Genus']]
          species = row[column_number_by_field_name['Species']]
          next if genus.blank? || species.blank?
          canonical = genus +" "+ species
          canonical = EOL::Sparql.to_underscore(canonical)

          data_line = "<http://anage.org/taxa/#{canonical}> a dwct:Taxon";
          data_line += "; eol:canonical <http://eol.org/canonical_forms/#{canonical}>"
          fields_to_ingest.each do |field_name, info|
            value = row[column_number_by_field_name[field_name]]
            unless value.blank?
              if info[:value_prefix]
                value = "<#{info[:value_prefix]}#{EOL::Sparql.to_underscore(value)}>"
              else
                value = EOL::Sparql.convert(value)
              end
              data_line += "; #{info[:uri]} #{value}"
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