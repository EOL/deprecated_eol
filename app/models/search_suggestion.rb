class SearchSuggestion < ActiveRecord::Base
   
  validates_presence_of :term,:scientific_name,:common_name,:language_label,:taxon_id
  validates_numericality_of :sort_order, :taxon_id
  validates_each :taxon_id do |model,attr,value|
    model.errors.add('Page ID','not a valid page') if TaxonConcept.find_by_id(value).nil?
  end
  
  def language
    name_language=Language.find_by_iso_639_1(self.language_label)
    if name_language.nil? 
      "Unknown"
    else
      name_language.name 
    end
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: search_suggestions
#
#  id              :integer(4)      not null, primary key
#  taxon_id        :string(255)     not null, default("")
#  active          :boolean(1)      not null, default(TRUE)
#  common_name     :string(255)     not null, default("")
#  content_notes   :string(255)     not null, default("")
#  image_url       :string(255)     not null, default("")
#  language_label  :string(255)     not null, default("en")
#  notes           :text
#  scientific_name :string(255)     not null, default("")
#  sort_order      :integer(4)      not null, default(1)
#  term            :string(255)     not null, default("")
#  created_at      :datetime
#  updated_at      :datetime

