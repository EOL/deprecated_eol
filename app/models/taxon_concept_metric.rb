class TaxonConceptMetric < SpeciesSchemaModel
  belongs_to :taxon_concept
  
  def richness_for_display
    sprintf("%.2f", richness_score * 100.00).to_f
  end
end
