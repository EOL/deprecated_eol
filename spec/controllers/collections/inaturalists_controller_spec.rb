require File.dirname(__FILE__) + '/../../spec_helper'

describe Collections::InaturalistsController do

  before(:all) do
    # Create a collection with a EOL collection id which already has a project on iNaturalist.
    @inat_collection = Collection.gen(:id => 5709, :name => 'Cape Cod')
    @inat_collection.users = [User.gen]
    @inat_collection.add(DataObject.gen)
    @inaturalist_project_info = @inat_collection.inaturalist_project_info
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it "should not show iNaturalists observations sub-tab if inaturalist project doesn't exist for the collection" do
      get :show, :collection_id => @inat_collection.id.to_i
      assigns[:collection].should be_a(Collection)
      assigns[:collection].id.should == @inat_collection.id
      assigns[:inaturalist_project_id].should == @inaturalist_project_info['id']
      assigns[:inaturalist_project_title].should == @inaturalist_project_info['title']
      assigns[:inaturalist_observed_taxa_count].should == @inaturalist_project_info['observed_taxa_count']
    end
  end

end