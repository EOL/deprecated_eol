
namespace :search do
  
  task :convert_he_to_taxon_concept_ids => :environment do 
    desc 'Convert he_ids to taxon_concept_ids for search suggestions table'
    
    # find all search suggestions 
     search_terms=SearchSuggestion.find(:all)
     
     # loop over search suggestions
     search_terms.each do |search_term|

       he=HierarchyEntry.find_by_id(search_term.taxon_id)

         if he
           puts 'Term: ' + search_term.term + ', found he id#' + he.id.to_s           
           t=he.taxon_concept
           if t
            search_term.taxon_id=t.id
            puts '***converted to taxon id: ' + t.id.to_s if search_term.save
           end      
         else
          puts '++++++ DID NOT FIND Term: ' + search_term.term 
         end 

       end
    
  end

  task :convert_taxon_concept_to_he_ids => :environment do 
    desc 'Convert taxon_concept_ids to he_ids for search suggestions table'
    
    # find all search suggestions 
     search_terms=SearchSuggestion.find(:all)
     
     # loop over search suggestions
     search_terms.each do |search_term|

       t=TaxonConcept.find_by_id(search_term.taxon_id)
       if t
         puts 'Term: ' + search_term.term + ', found taxon concept id#' + t.id.to_s
         he=t.hierarchy_entries
         if he
          search_term.taxon_id=he[0].id
          puts '***converted to he id: ' + he[0].id.to_s if search_term.save
         end      
       else
        puts '++++++ DID NOT FIND Term: ' + search_term.term 
       end   
       
     end
    
  end
end