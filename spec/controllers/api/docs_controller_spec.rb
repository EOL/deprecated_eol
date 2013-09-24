require File.dirname(__FILE__) + '/../../spec_helper'

describe Api::DocsController do
  before(:all) do
    load_foundation_cache
    # create some entry in the default hierarchy with an identifier - needed to render some API docs
    build_hierarchy_entry(0, TaxonConcept.gen, Name.gen, :identifier => 12345, :hierarchy => Hierarchy.default)
  end

  it 'there should be at least 9 API methods' do
    # [ :ping, :pages, :search, :collections, :data_objects, :hierarchy_entries, :hierarchies, :provider_hierarchies, :search_by_provider ]
    EOL::Api::METHODS.length.should >= 9
  end

  it "should load the class corresponding to each API method" do
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      # load the documentation page: e.g. api/docs/search
      get method_name
      assigns[:api_method].should == latest_version_method
    end
  end

  it "should have documentation for each version of the method" do
    EOL::Api::METHODS.each do |method_name|
      latest_version_method = EOL::Api.default_version_of(method_name)
      # load a version of the documentation page: e.g. api/docs/search/1.0
      get method_name, :version => latest_version_method::VERSION
      assigns[:api_method].should == latest_version_method

      # but asking for an unknown version will raise an error
      expect { get method_name, :version => 0.0 }.to raise_error
    end
  end
end
