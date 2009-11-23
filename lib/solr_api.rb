require 'net/http'
require 'uri'
require 'json'

class SolrAPI
  attr_reader  :server_url

  def initialize(server_url = nil)
    server_url ||= $SOLR_SERVER
    @server_url = URI.parse(server_url)
  end

  def delete_all_documents
    data = '<delete><query>*:*</query></delete>' 
    post('update', data)
    commit
  end

  def get_results(query)
    res = get(query)
    res = JSON.load res.body
    res['response']
  end

  def commit
    post('update', '<commit />')
  end

  def create(ruby_data)
    solr_xml = build_solr_xml('add', ruby_data)
    post('update', solr_xml)
  end

  def query
  end
  
  #Takes an array of hashes. Each hash has only string or array of strings values. Array is converted into an xml ready for either create or update methods of Solr API
  def build_solr_xml(command, ruby_data)
    builder = Nokogiri::XML::Builder.new do |sxml|
      sxml.send(command) do 
        ruby_data = [ruby_data] if ruby_data.class != Array
        ruby_data.each do |data|
          sxml.doc_ do
            data.keys.each do |key|
              data[key] = data[key].to_a if data[key].class != Array
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

  private

  def post(method, data) 
    request = Net::HTTP::Post.new(@server_url.path + "/#{method}")
    request.body = data
    request.content_type='application/xml'
    response = Net::HTTP.start(@server_url.host, @server_url.port) {|http| http.request(request)}
    #response == Net::HTTPSuccess ? response : response.error!
  end

  def get(query)
    response = Net::HTTP.start(@server_url.host, @server_url.port) {|http| http.get(@server_url.path + "/select/?q=*:*&version=2.2&start=0&rows=10&indent=on&wt=json")}
    response
  end

end
