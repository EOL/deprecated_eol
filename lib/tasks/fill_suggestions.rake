desc 'fill the curators_suggested_searches with default data'
namespace :suggested_searches do 
  task :fill_db => :environment do 
    CuratorsSuggestedSearch.create(label: "Which whales weigh more than 10,000 kg?", sort: 'desc', 
    from:10000, taxon_concept_id: 7649, uri: 'http://purl.obolibrary.org/obo/VT_0001259', 
     unit_uri: 'http://purl.obolibrary.org/obo/UO_0000009' )
     CuratorsSuggestedSearch.create(label: "What are the various shapes of diatoms?",
     q: 'cavity',  uri: 'http://eol.org/schema/terms/NestType')
     CuratorsSuggestedSearch.create( label: "Which species build cavity nests?",
          uri: 'http://purl.obolibrary.org/obo/OBA_0000052',
          taxon_concept_id: 3685 )
      CuratorsSuggestedSearch.create( label: "Which plants have blue flowers?",
          q: 'http://purl.obolibrary.org/obo/PATO_0000318',
          uri: 'http://purl.obolibrary.org/obo/TO_0000537')
  end
end