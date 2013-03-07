#!/usr/bin/env ruby
require 'rubygems'
require 'rest_client'
require 'linkeddata'

# Following http://www.jenitennison.com/blog/node/152

include RDF

query = %(PREFIX foaf: <http://xmlns.com/foaf/0.1/>
CONSTRUCT {
  ?person 
    a foaf:Person ;
    foaf:name ?name ;
    ?prop ?value .
} WHERE { 
  ?person a foaf:Person ;
    foaf:name ?name ;
    ?prop ?value .
})

endpoint = 'http://localhost:8000/sparql/'

puts "POSTing SPARQL query to #{endpoint}"
response = RestClient.post endpoint, :query => query
content_type = response.headers[:content_type][/^[^ ;]+/]
puts "Response #{response.code} type #{content_type}"

graph = RDF::Graph.new
graph << RDF::Reader.for(:content_type => content_type).new(response.to_str)

puts "\nLoaded #{graph.count} triples\n"

query = RDF::Query.new({
  :person => {
    RDF.type  => FOAF.Person,
    FOAF.name => :name,
    FOAF.mbox => :email,
  }
})

people = {}
query.execute(graph).each do |person|
  people[person.name.to_s] = person.email.to_s
end
puts "\nCreating directory of #{people.length} people"

stott_email = people['Andrew Stott']
puts "\nAndrew Stott's email address: #{stott_email}"

