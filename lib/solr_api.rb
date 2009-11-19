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
    data = '<delete><query>*:*</query></delete>' #{:delete => {:query => '*:*'}}.to_json
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

  def create
  end

  def query
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
