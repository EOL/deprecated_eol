# encoding: utf-8
require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

class SolrAPI
  attr_reader :server_url
  attr_reader :core
  attr_reader :primary_key
  attr_reader :schema_hash
  attr_reader :file_delimiter
  attr_reader :multi_value_delimiter
  attr_reader :csv_path
  attr_reader :action_url
  attr_reader :action_uri

  def self.text_filter(t)
    return nil if t.blank?
    return t if t.class == Fixnum
    return '' unless t.is_utf8?
    text = t.clone
    text.gsub!(/;/, ' ')
    text.gsub!(/×/, ' ')
    text.gsub!(/"/, ' ')
    text.gsub!(/'/, ' ')
    text.gsub!(/\|/, ' ')
    text.gsub!(/\n/, ' ')
    text.gsub!(/\r/, ' ')
    text.gsub!(/\t/, ' ')
    while text.match(/  /)
      text.gsub!(/  /, ' ')
    end
    text.strip
  end

  def self.ping(server_url, core = nil)
    begin
      test_connection = SolrAPI.new(server_url, core)
    rescue
      return false
    end
    # returns true if a connection was made the the schema loaded
    load_schema
    !test_connection.schema_hash.blank?
  end

  def initialize(server_url = nil, core = nil)
    @server_url = server_url
    @core = core
    @server_url ||= $SOLR_SERVER
    # make sure it ends with a slash
    @server_url += '/' unless @server_url[-1,1] == '/'

    @action_url = @server_url + @core.to_s
    # this one should NOT end in a slash
    @action_url = @action_url[0...-1] if @action_url[-1,1] == '/'
    @action_uri = URI.parse(action_url)

    @file_delimiter = '|'
    @multi_value_delimiter = ';'
    csv_path_random_bit = 10.times.map{ rand(10) }.join
    @stream_url = "http://#{EOL::Server.ip_address}/files/solr_import_file_#{csv_path_random_bit}.csv"
    @csv_path = Rails.root.join(Rails.public_path, 'files', "solr_import_file_#{csv_path_random_bit}.csv")
  end

  def load_schema
    return if @schema_hash && !@schema_hash.empty?
    schema_xml = SolrAPI.xml_get(@action_url + "/admin/file/?file=schema.xml")
    @primary_key = nil
    if pk = schema_xml.xpath('//uniqueKey').inner_text
      @primary_key = pk
    end
    @primary_key = nil if @primary_key.blank?

    # create empty hash that maps to each field name. The elements will be an array if the field is multi-valued
    @schema_hash = {}
    schema_xml.xpath('//fields/field').each do |field|
      field_name = field['name']
      multi_value = field['multiValued']

      if field['multiValued']
        @schema_hash[field_name.to_sym] = []
      else
        @schema_hash[field_name.to_sym] = ''
      end
    end
  end

  def swap(from_core, to_core)
    SolrAPI.http_get(@action_url + "/admin/cores/?action=SWAP&core=#{from_core}&other=#{to_core}")
  end

  def reload(core)
    SolrAPI.http_get(@action_url + "/admin/cores/?action=RELOAD&core=#{core}")
  end

  def delete_all_documents
    post_xml('update', '<delete><query>*:*</query></delete>')
    commit
    optimize
  end

  def obliterate
    delete_all_documents
    optimize
  end

  def delete_by_id(id, options={})
    delete_by_ids([ id ], options)
  end

  def delete_by_ids(ids, options={})
    post_xml('update', "<delete><id>"+ ids.join("</id><id>") +"</id></delete>")
    commit unless options[:commit] == false
  end

  def delete_by_query(query)
    post_xml('update', "<delete><query>#{query}</query></delete>")
    commit
  end

  def commit
    post_xml('update', '<commit />')
  end

  def optimize
    post_xml('update', '<optimize />')
  end

  def get_results(q)
    res = query(URI.encode(q))
    res = JSON.load res.body
    res['response']
  end


  # objects_hash should either be an array (if there is no primary key) or a hash indexed by the primary key
  # objects_hash = [ { :attr1 => :val11, :attr2 => :val21 }, { :attr1 => :val12, :attr2 => :val22 }]
  # or
  # objects_hash = { 1234 => { :attr1 => :val11, :attr2 => :val21 }, 522 => { :attr1 => :val12, :attr2 => :val22 } }
  def send_attributes(objects_hash, stream_file = true, delete_on_finish = true)
    # Currently I can't determine a reliable way to get a URL for the file for streaming.
    # If the app isn't running, there cannot be a URL as there is no web server to serve the file.
    # If the app is running, rake doesn't know about the request therefore it can't know the proper port
    stream_file = false if Rails.env.test?
    load_schema # make sure we know the fields. It will only be loaded once

    File.open(@csv_path, 'w') do |f|
      if @primary_key
        f.puts(@primary_key + @file_delimiter + @schema_hash.keys.join(@file_delimiter))
      else
        f.puts(@schema_hash.keys.join(@file_delimiter))
      end

      objects_hash = SolrAPI.array_to_hash(objects_hash) if objects_hash.class == Array
      objects_hash.each do |primary_key, object_fields|
        this_row_values = []
        # every row gets the primary key if it exists
        this_row_values << primary_key if @primary_key

        # get the valid fields from the given set of objects to index
        # looping through @schema_hash to make sure we get the fields in the same order for every row
        @schema_hash.each do |field, field_type|
          # this object has this attribute
          if value = object_fields[field] || value = object_fields[field.to_s]
            # the field is multi-values
            if field_type.class == Array
              if value.class == String
                value = [ value ]
              end
              raise "Multi-value fields must be arrays (#{@action_url} :: #{field})" if value.class != Array
              this_row_values << value.join(@multi_value_delimiter)
            else
              raise "Non multi-value fields cannot be arrays (#{@action_url} :: #{field})" if value.class == Array
              this_row_values << value
            end
          else
            # default value is empty string
            this_row_values << ""
          end
        end

        f.puts(this_row_values.join(@file_delimiter))
      end
    end

    fields = { 'separator' => file_delimiter, 'stream.contentType' => 'text/plain;charset=utf-8' }
    if stream_file
      # NOT THE LACK OF A PORT HERE
      fields['stream.url'] = @stream_url
    else
      fields['stream.file'] = @csv_path
    end
    @schema_hash.select{ |field, field_type| field_type.class == Array }.each do |field, field_type|
      fields["f.#{field}.split"] = true
      fields["f.#{field}.separator"] = @multi_value_delimiter
    end
    SolrAPI.post_fields(@action_url + "/update/csv", fields)
    commit

    # file = File.open(@csv_path)
    # while File.exists?(file.path)
    #     puts file.gets while !file.eof?
    # end

    File.delete(@csv_path) if delete_on_finish
  end

  # See the solr_api library spec for some examples.
  # This uses XML to send the data so it should only be used for small amounts of data.
  # Larger dataset should be sent using send_attributes which uses the CSV import mechanism
  def create(ruby_data)
    solr_xml = build_solr_xml('add', ruby_data)
    post_xml('update', solr_xml)
    commit
  end

  # Takes an array of hashes. Each hash has only string or array of strings values. Array is converted into an xml ready
  # for either create or update methods of Solr API
  #
  # See the solr_api library spec for some examples.
  def build_solr_xml(command, ruby_data)
    builder = Nokogiri::XML::Builder.new do |sxml|
      sxml.send(command) do
        ruby_data = [ruby_data] if ruby_data.class != Array
        ruby_data.each do |data|
          sxml.doc_ do
            data.keys.each do |key|
              data[key] = [data[key]] if data[key].class != Array
              data[key].each do |val|
                sxml.field(val, :name => key.to_s)
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end

  # This method creates indexes based on the *actual* TaxonConcept instances passed in as an argument (enumerable).
  def build_indexes(taxon_concepts = nil)
    taxon_concepts ||= TaxonConcept.all(:include => [ { :taxon_concept_names => :name }, :flattened_ancestors ] )
    data = {}
    taxon_concepts.each do |taxon_concept|
      best_image = taxon_concept.exemplar_or_best_image_from_solr
      data[taxon_concept.id] = {:common_name => taxon_concept.all_common_names,
               :preferred_scientific_name => [taxon_concept.title],
               :scientific_name => taxon_concept.all_scientific_names,
               :ancestor_taxon_concept_id => taxon_concept.flattened_ancestors.
                 map {|a| a.ancestor_id }.sort.uniq,
               :vetted_id => taxon_concept.vetted_id,
               :published => taxon_concept.published,
               :supercedure_id => taxon_concept.supercedure_id,
               :top_image_id => best_image.blank? ? [] : [best_image.id] }
    end
    send_attributes(data)
  end

  def build_data_object_index(data_objects = nil)
    data_objects ||= DataObject.all
    data = {}
    data_objects.each do |data_object|
      this_object_hash = {}
      this_object_hash[:guid] = data_object.guid
      this_object_hash[:data_type_id] = data_object.data_type_id
      this_object_hash[:published] = data_object.published ? 1 : 0
      this_object_hash[:data_rating] = data_object.data_rating
      this_object_hash[:created_at] = data_object.created_at.solr_timestamp
      if concept = data_object.linked_taxon_concept
        this_object_hash[:taxon_concept_id] = [concept.id]
        this_object_hash[:ancestor_id] = concept.entry.ancestors.map { |a| a.taxon_concept.id } if concept.entry
      end
      if harvest_events = data_object.harvest_events
        unless harvest_events.blank?
          this_object_hash[:resource_id] = harvest_events.last.resource_id
        end
      end
      data[data_object.id] = this_object_hash
    end
    send_attributes(data)
  end

  def query_lucene(q, options = {})
    EOL::Solr.query_lucene(@action_url, q, options)
  end






  private

  def self.http_get(url)
    Net::HTTP.get(URI.parse(url))
  end

  def self.json_get(url)
    JSON.parse(http_get(url))
  end

  def self.xml_get(url)
    Nokogiri.XML(http_get(url))
  end

  def self.post_fields(url, fields)
    Net::HTTP.post_form(URI.parse(url), fields)
  end

  def get_port
    ping_host_response = SolrAPI.json_get('/api/ping_host')
  end

  def self.array_to_hash(array)
    i = -1
    Hash[array.collect{ |v| [i+=1, v] }]
  end

  def query(query)
    response = Net::HTTP.start(@action_uri.host, @action_uri.port) {|http| http.get(@action_url + "/select/?q=#{query}&version=2.2&start=0&rows=10&indent=on&wt=json") }
  end

  def post_xml(method, xml)
    post_url = @action_url + "/#{method}"
    request = Net::HTTP::Post.new(post_url)
    request.body = xml
    request.content_type = 'application/xml'
    response = Net::HTTP.start(@action_uri.host, @action_uri.port) do |http|
      http.open_timeout = 30
      http.read_timeout = 240
      http.request(request)
    end
    rescue Timeout::Error => e
      puts "Timeout accessing #{post_url}"
      pp e.message
      pp e.backtrace
      nil
    rescue => e
      puts "Error accessing #{post_url}"
      pp e.message
      pp e.backtrace
      nil
  end
end
