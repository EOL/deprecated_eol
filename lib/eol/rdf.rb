module EOL
  module RDF

    def self.create_col_rdf
      min_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).minimum('hierarchy_entries.id') || 0
      max_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).maximum('hierarchy_entries.id') || 0

      iteration_size = 100000
      start = min_id
      filepath = File.join(Rails.root, 'tmp', 'col.rdf')
      f = File.new(filepath, 'w+')
      f.write("<rdf:RDF
        xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
        xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"
        xmlns:eol=\"http://eol.org/schema#\"
        xmlns:dwc=\"http://rs.tdwg.org/dwc/terms/\">\n")
      until start > max_id
        results = HierarchyEntry.connection.execute("
          SELECT he.id, he.parent_id, n.string, tr.label
          FROM hierarchy_entries he
          LEFT JOIN names n ON (he.name_id=n.id)
          LEFT JOIN ( ranks r JOIN translated_ranks tr ON (r.id=tr.rank_id AND tr.language_id=#{Language.default.id}) ) ON he.rank_id=r.id
          WHERE he.hierarchy_id=#{Hierarchy.col.id} AND he.id BETWEEN #{start} AND #{start + iteration_size - 1}")
        results.each do |result|
          hierarchy_entry_id = result[0]
          parent_id = result[1]
          name_string = result[2]
          rank_label = result[3]
          f.write("  <rdf:Description rdf:about=\"http://eol.org/hierarchy_entries/#{hierarchy_entry_id}\">\n")
          f.write("    <dwc:scientificName>#{convert(name_string)}</dwc:scientificName>\n") unless name_string.blank?
          if parent_id.blank? || parent_id == 0
            f.write("    <dwc:parentNameUsageID rdf:resource=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#:nil\"/>\n")
          else
            f.write("    <dwc:parentNameUsageID rdf:resource=\"http://eol.org/hierarchy_entries/#{parent_id}\"/>\n")
          end
          f.write("    <dwc:verbatimRank>#{rank_label}</dwc:verbatimRank>\n") unless rank_label.blank?
          f.write("  </rdf:Description>\n")
        end
        start += iteration_size
      end
      f.write("</rdf:RDF>")
      f.close
    end

    def self.load_catalogue_of_life
      min_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).minimum('hierarchy_entries.id') || 0
      max_id = Hierarchy.where(:id => Hierarchy.col.id).joins(:hierarchy_entries).maximum('hierarchy_entries.id') || 0

      recreate_graph('CatalogueOfLife')
      iteration_size = 100000
      start = min_id
      data = []
      until start > max_id
        results = HierarchyEntry.connection.execute("
          SELECT he.id, he.parent_id, n.string, tr.label
          FROM hierarchy_entries he
          LEFT JOIN names n ON (he.name_id=n.id)
          LEFT JOIN ( ranks r JOIN translated_ranks tr ON (r.id=tr.rank_id AND tr.language_id=#{Language.default.id}) ) ON he.rank_id=r.id
          WHERE he.hierarchy_id=#{Hierarchy.col.id} AND he.id BETWEEN #{start} AND #{start + iteration_size - 1}")
        results.each do |result|
          hierarchy_entry_id = result[0]
          parent_id = result[1]
          name_string = result[2]
          rank_label = result[3]

          data_line = "<http://eol.org/hierarchy_entries/#{hierarchy_entry_id}> dwc:scientificName '#{convert(name_string)}'"
          data_line += "; dwc:verbatimRank '#{rank_label}'" unless rank_label.blank?
          if parent_id.blank? || parent_id == 0
            data_line += "; dwc:parentNameUsageID <http://www.w3.org/1999/02/22-rdf-syntax-ns#:nil>"
          else
            data_line += "; dwc:parentNameUsageID <http://eol.org/hierarchy_entries/#{parent_id}>"
          end
          data << data_line
          if data.length >= 10000
            insert_data(data, 'CatalogueOfLife')
            data = []
          end
        end
        start += iteration_size
      end
      insert_data(data, 'CatalogueOfLife')
    end

    def self.load_users
      min_id = User.minimum(:id) || 0
      max_id = User.maximum(:id) || 0

      recreate_graph('Users')
      iteration_size = 100000
      start = min_id
      data = []
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

          data_line = "<http://eol.org/users/#{user_id}> rdfs:Class foaf:Person"
          data_line += "; foaf:firstName '#{convert(given_name)}'" unless given_name.blank?
          data_line += "; foaf:familyName '#{convert(family_name)}'" unless family_name.blank?
          data_line += "; dc:language '#{convert(language_iso)}'" unless language_iso.blank?
          data_line += "; eol:curatorLevel eol:#{curator_level_label.tr(' ','').camelize(:lower)}" unless curator_level_label.blank?
          data << data_line
          if data.length >= 10000
            insert_data(data, 'Users')
            data = []
          end
        end
        start += iteration_size
      end
    end

    def self.insert_data(data, graph_name, options = {})
      return if data.blank?
      @@total_data_inserted ||= 0
      @@total_data_inserted += data.length
      puts "Inserting records #{@@total_data_inserted}..."
      virtuoso_api = VirtuosoAPI.new(
        :instance_uri => 'http://localhost:8890',
        :upload_path => '/DAV/xx/yy',
        :username => 'demo',
        :password => 'demo')
      virtuoso_api.insert_data(:data => data, :graph_name => graph_name)
    end

    def self.recreate_graph(graph_name)
      sparql = SPARQL::Client.new("http://localhost:8890/sparql")
      # sparql.query("DEFINE sql:log-enable 3 CLEAR GRAPH <#{graph_name}>") rescue puts "***Graph <#{graph_name}> probably didn't exist***"
      sparql.query("DROP GRAPH <#{graph_name}>") rescue puts "***Graph <#{graph_name}> probably didn't exist***"
      sparql.query("CREATE GRAPH <#{graph_name}>")
    end

    def self.convert(str)
       str.gsub!("&", "&amp;")
       str.gsub!("<", "&lt;")
       str.gsub!(">", "&gt;")
       str.gsub!("'", "&apos;")
       str.gsub!("\"", "&quot;")
       str.gsub!("\\", "")
       str.gsub!("\n", "")
       str.gsub!("\r", "")
       str
    end

  end
end