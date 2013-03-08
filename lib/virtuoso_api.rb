class VirtuosoAPI
  attr_accessor :instance_uri, :upload_path, :namespaces, :username, :password

  def initialize(options={})
    self.instance_uri = options[:instance_uri]
    self.upload_path = options[:upload_path]
    self.username = options[:username]
    self.password = options[:password]

    self.namespaces = {
      'dwc' => 'http://rs.tdwg.org/dwc/terms/',
      'dwct' => 'http://rs.tdwg.org/dwc/dwctype/',
      'dc' => 'http://purl.org/dc/terms/',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'foaf' => 'http://xmlns.com/foaf/0.1/',
      'eol' => 'http://eol.org/schema/terms/',
      'obis' => 'http://iobis.org/schema/terms/',
      'anage' => 'http://anage.org/schema/terms/'
    }
  end

  def insert_data(options={})
    unless options[:data].blank?
      query = namespaces.collect{ |key,value| "PREFIX #{key}: <#{value}>"}.join(" ")
      query += " INSERT DATA INTO <#{options[:graph_name]}> { "+ options[:data].join(" .\n") +" }"
      uri = URI(instance_uri + upload_path)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(username, password)
      request.body = query
      request.content_type = 'application/sparql-query'

      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.open_timeout = 30
        http.read_timeout = 240
        http.request(request)
      end
      pp response
      if response.code.to_i != 201
        pp query
      end
    end
  end

end