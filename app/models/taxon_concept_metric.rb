class TaxonConceptMetric < SpeciesSchemaModel
  belongs_to :taxon_concept
  
  def richness_for_display(decimal_places = 2)
    sprintf("%.#{decimal_places}f", richness_score * 100.00).to_f
  end
end
