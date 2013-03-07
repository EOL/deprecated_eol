#!/usr/bin/env ruby
require 'rubygems'
require 'rest_client'
require 'nokogiri'

# Following http://www.jenitennison.com/blog/node/152

if false # This is the non-sparql-client solution:
  query = 'SELECT DISTINCT ?type WHERE { ?thing a ?type . } ORDER BY ?type'
  endpoint = 'http://localhost:8000/sparql/'
  puts "POSTing SPARQL query to #{endpoint}"
  response = RestClient.post endpoint, :query => query
  puts "Response #{response.code}"
  Nokogiri::XML(response.to_str).xpath(
      '//sparql:binding[@name = "type"]/sparql:uri',
      'sparql' => 'http://www.w3.org/2005/sparql-results#').each do |type|
    puts type.content
  end
end

require 'sparql/client'

query    = 'SELECT DISTINCT ?type WHERE { ?thing a ?type } ORDER BY ?type'
endpoint = SPARQL::Client.new('http://localhost:8000/sparql/')

puts "POSTing SPARQL query to #{endpoint.url.host}:#{endpoint.url.port}"
endpoint.query(query).each do |solution|
    puts solution[:type]
end

