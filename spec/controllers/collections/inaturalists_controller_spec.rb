require File.dirname(__FILE__) + '/../../spec_helper'

describe Collections::InaturalistsController do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    # Create a collection with a EOL collection id which already has a project on iNaturalist.
    @inat_collection = Collection.gen(:id => 28064, :name => "Exploring Odiorne Point's Tidepools")
    @inat_collection.users = [User.gen]
    @inat_collection.add(DataObject.gen)
    @inaturalist_project_info = @inat_collection.inaturalist_project_info
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
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
