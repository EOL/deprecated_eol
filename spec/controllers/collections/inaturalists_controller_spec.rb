require File.dirname(__FILE__) + '/../../spec_helper'

describe Collections::InaturalistsController do

  before(:all) do
    load_foundation_cache
    # Create a collection with a EOL collection id which already has a project on iNaturalist.
    $TESTING_INATURALIST_PROJECTS = true
    @inat_collection = Collection.gen(:id => 31199, :name => "CoMBIN")
    @inat_collection.users = [User.gen]
    @inat_collection.add(DataObject.gen)
    @inaturalist_project_info = @inat_collection.inaturalist_project_info
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  before(:each) do
    $TESTING_INATURALIST_PROJECTS = true
  end

  after(:each) do
    $TESTING_INATURALIST_PROJECTS = false
  end

  describe 'GET show' do
    it "should instantiate the collection and other inaturalist project related variables" do
      get :show, :collection_id => @inat_collection.id.to_i
      assigns[:collection].should be_a(Collection)
      assigns[:collection].id.should == @inat_collection.id
      assigns[:inaturalist_project_id].should == @inaturalist_project_info['id']
      assigns[:inaturalist_project_title].should == @inaturalist_project_info['title']
      assigns[:inaturalist_observed_taxa_count].should == @inaturalist_project_info['observed_taxa_count']
    end
  end

end
