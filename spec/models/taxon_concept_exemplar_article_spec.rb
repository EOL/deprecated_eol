require "spec_helper"

describe TaxonConceptExemplarArticle do

  before do
    TaxonConceptCacheClearing.stub(:clear_overview_article_by_id).and_return(nil)
  end

  it '#set_exemplar should add/update exemplar article record for taxon concept' do
    TaxonConceptExemplarArticle.set_exemplar(567, 123)
    tcea = TaxonConceptExemplarArticle.last
    tcea.taxon_concept_id.should == 567
    tcea.data_object_id.should == 123
    TaxonConceptExemplarArticle.set_exemplar(567, 789)
    tcea.reload
    tcea.taxon_concept_id.should == 567
    tcea.data_object_id.should == 789
  end

  it 'should clear cache' do
    TaxonConceptCacheClearing.should_receive(:clear_overview_article_by_id).with(234)
    TaxonConceptExemplarArticle.set_exemplar(234, 345)
  end

end
