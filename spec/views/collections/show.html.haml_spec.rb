describe 'collections/show' do
   before(:all) do
    Language.create_english
    UriType.create_enumerated
    Vetted.create_enumerated
    Visibility.create_enumerated
    License.create_enumerated
    ContentPartnerStatus.create_enumerated
    DataType.create_enumerated
    SortStyle.create_enumerated
    ViewStyle.create_enumerated
  end
  
  before do
    collection_item_hidden = CollectionItem.gen
    hidden_do = DataObject.find(collection_item_hidden.collected_item_id)
    hidden_do.update_attributes(object_cache_url: 201105040529974)
    collection_item_hidden.reload
    dohe_hidden = DataObjectsHierarchyEntry.gen
    dohe_hidden.update_attributes( data_object_id: collection_item_hidden.collected_item_id, 
      visibility_id: Visibility.invisible.id )
    
    collection_item_visible = CollectionItem.gen
    visible_do = DataObject.find(collection_item_visible.collected_item_id)
    visible_do.update_attributes(object_cache_url: 201105040529974)
    collection_item_visible.reload
    dohe_visible = DataObjectsHierarchyEntry.gen
    dohe_visible.update_attributes( data_object_id: collection_item_visible.collected_item_id, 
      visibility_id: Visibility.visible.id )
    
    collection_items = [collection_item_hidden, collection_item_visible]
    collection = Collection.new
    collection_job = CollectionJob.new
    collection.stub(:editable_by?).and_return(false)
    collection.stub(:maintained_by).and_return([])
    collection.stub(:relevance).and_return([])
    collection.stub(:featuring_communities).and_return([])
    collection.stub(:watch_collection?).and_return(false)
    collection.stub(:id).and_return(1)
    collection.stub(:inaturalist_project_info).and_return(nil)
    collection.stub(:collection_items).and_return(collection_items)
    assign(:collection_job, collection_job)
    assign(:sort_by, SortStyle.alphabetical)
    assign(:view_as_options, {})
    assign(:sort_options, {})
    assign(:collection, collection)  
    assign(:collection_items, collection_items)  
    # collection_results = WillPaginate::Collection.new(1,1)
    assign(:collection_results,  [@collection1].paginate)
    # assign(:collection_results, collection_results)
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_language) { Language.default }
    view.stub(:logged_in?) { false }
    assign(:assistive_section_header, 'assist my overview')
    assign(:rel_canonical_href, 'some canonical stuff')
    user = EOL::AnonymousUser.new(Language.default)
    view.stub(:current_user) { user }
  end
  
  it "should display hidden for hidden image in list view" do
    assign(:view_as, ViewStyle.list)
    render
    expect(rendered).to have_tag("li.image", count: 2)
    expect(rendered).to have_tag("p.flag.untrusted", count: 1)
  end
  
  it "should display hidden for hidden image in annotated view" do
    assign(:view_as, ViewStyle.annotated)
    render
    expect(rendered).to have_tag("li.image", count: 2)
    expect(rendered).to have_tag("p.flag.untrusted", count: 1)
  end
  
  it "should display hidden for hidden image in gallery view" do
    assign(:view_as, ViewStyle.gallery)
    render
    expect(rendered).to have_tag("li.image", count: 2)
    expect(rendered).to have_tag("label.hiddenoverlay", count: 1)
  end
end