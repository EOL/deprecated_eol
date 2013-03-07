#!/usr/bin/env ruby
require 'rubygems'
require 'rest_client'

# Following http://www.jenitennison.com/blog/node/152

filename = './4store/index.rdf'
graph    = 'http://source.data.gov.uk/data/reference/organogram-co/2010-06-30'
endpoint = 'http://localhost:8000/data/'

puts "Loading #{filename} into #{graph} in 4store"
response = RestClient.put endpoint + graph, File.read(filename), :content_type => 'application/rdf+xml'
puts "Response #{response.code}:\n#{response.to_str}"

# In the comments it was noted that using rdf-4store <https://github.com/fumi/rdf-4store> would make this simpler:
if false
  # ... Note that to use that gem, you need to start 4store with unsafe mode, which I didn't want to do:
  # 4s-backend reference ; 4s-httpd -U -s -1 reference
  repository = RDF::FourStore::Repository.new('http://localhost:8080/')
  repository.load(filename_or_url)
end
