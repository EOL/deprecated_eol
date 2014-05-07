class SearchSuggestion < ActiveRecord::Base

  belongs_to :taxon_concept, foreign_key: :taxon_id

  validates_presence_of :term, :language_label, :taxon_id
  validates_numericality_of :sort_order, :taxon_id
  validates_each :taxon_id do |model, attr, value|
    model.errors.add('Page ID', 'not a valid page') if TaxonConcept.find_by_id(value).nil?
  end

  def language
    name_language = Language.find_by_iso_639_1(self.language_label)
    if name_language.nil?
      "Unknown"
    else
      name_language.source_form
    end
  end

end
