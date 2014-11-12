describe 'collections/show' do
  before do
    collection = double(Collection, :editable_by? => false, maintained_by: [], relevance: [])
    assign(:collection, collection)  
    view.stub(:meta_open_graph_data).and_return([])
    view.stub(:tweet_data).and_return({})
    view.stub(:current_language) { Language.default }
    assign(:assistive_section_header, 'assist my overview')
    assign(:rel_canonical_href, 'some canonical stuff')
    user = EOL::AnonymousUser.new(Language.default)
    view.stub(:current_user) { user }
  end
  it "should render collections/show" do
    render
  end
end