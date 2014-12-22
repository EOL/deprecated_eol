describe 'layouts/data' do

  before(:all) do
    License.create_enumerated
    Language.create_english
    Vetted.create_enumerated
    Visibility.create_enumerated
    DataType.create_enumerated
    CuratorLevel.create_enumerated
    SpecialCollection.create_enumerated
    c = Collection.gen
    @anonymous_user = User.gen
    @curator = User.gen
    @curator.update_attributes(curator_approved: 1, curator_level_id: CuratorLevel.full.id)
    @curator.build_watch_collection
    @master_curator = User.gen
    @master_curator.update_attributes(curator_approved: 1, curator_level_id: CuratorLevel.master.id)
    @master_curator.build_watch_collection
  end
  
  before(:each) do
    view.stub(:meta_data) { { title: 'The title' } }
    view.stub(:current_url) { 'http://yes.we/really_have/this-helper.method' }
    view.stub(:current_language) { Language.default }
  end
  
  context "published data_object" do
    before(:all) do
      d = DataObject.gen
      assign(:data_object, d)
      assign(:latest_published_revision, d)
    end
    
    it "doesn't display delete button for anonymous user" do
      view.stub(:current_user) { @anonymous_user }
      view.stub(:logged_in?) { false }
      render 
      expect(rendered).not_to have_tag("a.button", text: "delete")
    end
    
    it "doesn't display delete button for full curator or less" do
      view.stub(:current_user) { @curator }
      view.stub(:logged_in?) { true }
      render 
      expect(rendered).not_to have_tag("a.button", text: "delete")
    end
    
    it "displays delete button for master curator" do
      view.stub(:current_user) { @master_curator }
      view.stub(:logged_in?) { true }
      render
      expect(rendered).to have_tag("a.button", text: "#{I18n.t(:delete_data_object)}")
    end
  end
  
  context "unpublished data_object" do
    before(:all) do
      d = DataObject.gen
      d.published = false
      d.save
      assign(:data_object, d)
      assign(:latest_published_revision, d)
    end
    
    it "doesn't display delete button" do
      view.stub(:current_user) { @master_curator }
      view.stub(:logged_in?) { true }
      render 
      expect(rendered).not_to have_tag("a.button", text: "delete")
    end
  end
end