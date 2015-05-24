class CollectionFromListString < ActiveRecord::Base
  belongs_to :collection_from_list
  has_many :matches, class_name: "CollectionFromListMatch"
  scope :exact, where(exact: true)
  scope :multiple, where(exact: false, unmatched: false)
  scope :unmatched, where(unmatched: true)

  attr_accessible :id, :string, :collection_from_list
  
  # Lots of work here, which creates all the matches AND sets the exact/unmatched flags on this model
  def find_matches
    is_integer? ? handle_integer_string : handle_text_string
  end
  
  private
  def handle_integer_string
    debugger
    taxa =  TaxonConcept.where(id: string.to_i)
    taxa.blank? ? handle_unmatched_string : handle_exactly_matched_string(taxa.first.id)  
  end
  
  def handle_text_string
    taxa = EOL::Solr::SiteSearch.taxon_search_with_limit(string, 
      {sort_by: 'score', type: ['TaxonConcept'], exact: false, language_id: current_language.id})[:taxa]
    if taxa.count == 0 # there is no exact match or suggestions
      handle_unmatched_string
   elsif taxa.count == 1 #there is one exact match
     handle_exactly_matched_string(TaxonConcept.find(taxa.first["instance"].id))
   else #there are suggetions
      handle_multiple_match_string(taxa)
    end
  end
  
  def handle_exactly_matched_string(taxon_concept_id)
    CollectionFromListMatch.create(string_id: id, taxon_concept_id: taxon_concept_id)
    update_attributes(exact: true)
  end
  
  def handle_unmatched_string
    update_attributes(unmatched: true)
  end
  
  def handle_multiple_match_string(taxa)
    taxa.each do |res|
      CollectionFromListMatch.create(string_id: id, taxon_concept_id: res["instance"].id)
    end
    update_attributes(exact: false, unmatched: false)
  end
  
  def is_integer?
   /^\d*$/ === string
  end
end