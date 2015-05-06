require File.dirname(__FILE__) + '/../../spec_helper'


describe Taxa::ResourcesController do

  before(:all) do
    load_foundation_cache
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
  end

  describe 'GET education' do

    it 'should find Education Resources items when there are some' do
      taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :toc => [], :bhl => [])
      get :education, :taxon_id => taxon_concept.id
      assigns[:education_contents].blank?.should == true
      education_object = DataObject.create(data_type: DataType.text, description: 'asd', published: 1)
      taxon_concept.add_object_as_subject(education_object, 'Education Resources')
      get :education, :taxon_id => taxon_concept.id
      assigns[:education_contents].first.should == education_object
    end

    it 'should find Education Resources items when there are some' do
      taxon_concept = build_taxon_concept(:comments => [], :images => [], :flash => [], :youtube => [], :sounds => [], :toc => [], :bhl => [])
      get :education, :taxon_id => taxon_concept.id
      assigns[:education_contents].blank?.should == true
      education_object = DataObject.create(data_type: DataType.text, description: 'asd', published: 1)
      taxon_concept.add_object_as_subject(education_object, 'Education')
      get :education, :taxon_id => taxon_concept.id
      assigns[:education_contents].first.should == education_object
    end

  end

end
