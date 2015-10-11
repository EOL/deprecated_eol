# This is meant to be #include'd.
module VirtuosoHelpers
  def drop_all_virtuoso_graphs
    EOL::Sparql::VirtuosoClient.drop_all_graphs
  end
  
  def add_measurement_to_virtuoso(options = {})
    DataMeasurement.new(:predicate => "http://eol.org/schema/terms/weigth", 
                         :object => options[:value].to_s, 
                         :resource => Resource.last, 
                         :subject => TaxonConcept.find(1), 
                         :unit => "http://purl.obolibrary.org/obo/UO_0000009", 
                         :life_stage => options[:stage], 
                         :sex => options[:sex], 
                         :statistical_method => options[:method], 
                         :normalized_value => (options[:value] * 10).to_s, 
                         :normalized_unit => "http://purl.obolibrary.org/obo/UO_0000021").add_to_triplestore
            
  end
end
