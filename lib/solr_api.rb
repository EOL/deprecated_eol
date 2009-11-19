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
    res = post('update', data)
    commit
  end

  def get_results(query)
    pp get(query)   
  end

  def commit
    res = post('update', '<commit />')
  end

  private

  def post(method, data) 
    request = Net::HTTP::Post.new(@server_url.path + "/#{method}")
    request.body = data
    request.content_type='application/xml'
    response = Net::HTTP.start(@server_url.host, @server_url.port) {|http| http.request(request)}
    response == Net::HTTPSuccess ? response : response.error!
  end

  def get(query)
    response = Net::HTTP.stasrt(@server_url.host, @server_url.port) {|http| http.request(@server_url.path + "/search/?#{URI.escape(query)}&version=2.2&start=0&rows=10&indent=on&wt=json")}
    response == Net::HTTPSuccess ? response : response.error!
  end
  
end
