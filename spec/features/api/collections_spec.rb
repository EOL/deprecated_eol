require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:collections' do
  before(:all) do
    load_foundation_cache
    @collection = Collection.gen(name: "TESTING COLLECTIONS API", description: "SOME DESCRIPTION")
  end

  before(:each) do
    @collection.collection_items.destroy_all
    @collection.reload
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  it 'should return XML' do
    response = get_as_xml("/api/collections/#{@collection.id}.xml")
    response.xpath("/response/name").inner_text.should == @collection.name
    response.xpath("/response/description").inner_text.should == @collection.description
  end

  it 'should return JSON' do
    response = get_as_json("/api/collections/#{@collection.id}.json")
    response.class.should == Hash
    response['name'].should == @collection.name
    response['description'].should == @collection.description
  end

  it 'should return XML by default when no extension is provided' do
    response = get_as_xml("/api/collections/#{@collection.id}")
    response.xpath("/response/name").inner_text.should == @collection.name
    response.xpath("/response/description").inner_text.should == @collection.description
  end

  it 'should be able to filter by sort_field in XML' do
    ci1 = CollectionItem.gen(collection: @collection, collected_item: User.gen)
    ci2 = CollectionItem.gen(collection: @collection, collected_item: User.gen, sort_field: "populated")
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
    response = get_as_xml("/api/collections/#{@collection.id}")
    response.xpath("//item").length.should == 2

    response = get_as_xml("/api/collections/#{@collection.id}?sort_field=populated")
    response.xpath("//item").length.should == 1
    response.xpath("//item/sort_field").inner_text.should == 'populated'
  end

  it 'should be able to filter by sort_field in XML' do
    ci1 = CollectionItem.gen(collection: @collection, collected_item: User.gen)
    ci2 = CollectionItem.gen(collection: @collection, collected_item: User.gen, sort_field: "populated")
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
    response = get_as_json("/api/collections/#{@collection.id}.json")
    response['collection_items'].length.should == 2

    response = get_as_json("/api/collections/#{@collection.id}.json?sort_field=populated")
    response['collection_items'].length.should == 1
    response['collection_items'].first['sort_field'].should == 'populated'
  end
end
