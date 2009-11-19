require File.dirname(__FILE__) + '/../spec_helper'

describe SolrAPI do
  before(:all) do
    @solr = SolrAPI.new
  end

  it 'should connect to solr server from environment' do
    @solr.server_url.host.should == 'localhost'
    @solr.server_url.path.should == '/solr'
    @solr.server_url.port.should == 8983
  end

  it 'should be able to run search on the server' do
    @solr.delete_all_documents
    @solr.get_results("*:*")['numFound'].class.should == 0
  end


end
