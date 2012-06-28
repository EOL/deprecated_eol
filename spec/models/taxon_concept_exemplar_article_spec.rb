require File.dirname(__FILE__) + '/../spec_helper'

describe TaxonConceptExemplarArticle do

  before :all do
    truncate_all_tables
  end

  it '#set_exemplar should add/update exemplar article record for taxon concept' do
    taxon_concept = TaxonConcept.gen
    DataType.gen_if_not_exists(:label => 'Text', :schema_value => 'http://purl.org/dc/dcmitype/Text')
    data_object = DataObject.gen(:data_type_id => DataType.text.id, :published => 1)
    TaxonConceptExemplarArticle.set_exemplar(taxon_concept.id, data_object.id)
    tcea = TaxonConceptExemplarArticle.last
    tcea.taxon_concept_id.should == taxon_concept.id
    tcea.data_object_id.should == data_object.id
    new_data_object = DataObject.gen(:data_type_id => DataType.text.id, :published => 1)
    TaxonConceptExemplarArticle.set_exemplar(taxon_concept.id, new_data_object.id)
    tcea.reload
    tcea.taxon_concept_id.should == taxon_concept.id
    tcea.data_object_id.should == new_data_object.id
  end

end
