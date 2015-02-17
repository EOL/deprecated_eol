require "spec_helper"

def data_object_create_edit_variables_should_be_assigned
  assigns[:data_object].should be_a(DataObject)
  assigns[:toc_items].should_not be_nil
  assigns[:toc_items].first.should be_a(TocItem)
  assigns[:toc_items].select{|ti| ti.id == assigns[:selected_toc_item_id]}.first.should be_a(TocItem)
  assigns[:languages].first.should be_a(Language)
  assigns[:licenses].first.should be_a(License)
  assigns[:page_title].should be_a(String)
  assigns[:page_description].should be_a(String)
end

describe DataObjectsController do
  before(:all) do
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen
    @user = User.gen
    @udo = @taxon_concept.add_user_submitted_text(:user => @user)
  end

  # GET /pages/:taxon_id/data_objects/new
  describe 'GET new' do
    it 'should render new if logged in' do
      get :new, { :taxon_id => @taxon_concept.id } # not logged in
      response.should render_template(nil)
      expect(response).to redirect_to('/login')
      get :new, { :taxon_id => @taxon_concept.id }, { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      assigns[:data_object].new_record?.should be_true
      response.should render_template('data_objects/new')
    end
  end

  describe 'POST create' do
    it 'should instantiate references' do
      post :create, { :taxon_id => @taxon_concept.id, :references => "Test reference.",
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.text.id.to_s,
                                        :object_title => "Test Article", :language_id => Language.english.id.to_s,
                                        :description => "Test text", :license_id => License.public_domain.id.to_s} },
                      { :user => @user, :user_id => @user.id }
      assigns[:references].should == "Test reference."
    end
    it 'should re-render new if model validation fails' do
      post :create, { :taxon_id => @taxon_concept.id,
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.text.id.to_s,
                                        :object_title => 'Blank description will fail validation',
                                        :description => '' } },
                    { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      response.should render_template('data_objects/new')
    end
    it 'should create Link objects and prefix URLs with http://' do
      EOLWebService.should_receive('url_accepted?').with('http://eol.org').and_return(true)
      post :create, { :taxon_id => @taxon_concept.id, :commit_link => true,
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.text.id.to_s,
                                        :link_types => { :id => LinkType.blog.id.to_s }, :source_url => 'eol.org',
                                        :object_title => "Link to EOL", :language_id => Language.english.id.to_s,
                                        :description => "Link text" } },
                      { :user => @user, :user_id => @user.id }
      DataObject.exists?(assigns[:data_object]).should == true
      assigns[:data_object].link?.should == true
      assigns[:data_object].data_type.should == DataType.text
      assigns[:data_object].data_subtype.should == DataType.link
      assigns[:data_object].link_type.should == LinkType.blog
      assigns[:data_object].toc_items.should == [ TocItem.overview ]
      assigns[:data_object].source_url.should == "http://eol.org"  # even though it was submitted as eol.org
    end
    it 'fails validation on invalid link URLs' do
      EOLWebService.should_receive('url_accepted?').at_least(3).times.with('http://').and_return(false)
      post :create, { :taxon_id => @taxon_concept.id, :commit_link => true,
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.text.id.to_s,
                                        :link_types => { :id => LinkType.blog.id.to_s }, :source_url => 'http://',
                                        :object_title => "Link to EOL", :language_id => Language.english.id.to_s,
                                        :description => "Link text" } },
                      { :user => @user, :user_id => @user.id }
      expect(assigns[:data_object]).to have(1).error_on(:source_url)
      expect(assigns[:data_object].errors_on(:source_url)).to include(I18n.t(:url_not_accessible))
    end

       it 'fails when a duplicate text is added' do 
       dato = { toc_items: { id: TocItem.overview.id.to_s },  data_type_id: DataType.text.id.to_s,
               object_title: "title", language_id: Language.english.id.to_s,
               description: "text" }
       post :create, { taxon_id: @taxon_concept.id,
                      data_object: dato },{ user: @user, user_id: @user.id }
       post :create, { taxon_id: @taxon_concept.id, 
                      data_object: dato },{ user: @user, user_id: @user.id }
      expect(flash[:notice]).to eq(I18n.t(:duplicate_text_warning))
      expect(response).to render_template(:new)
    end
    it 'passes when a non-duplicate text is added' do
       dato = { toc_items: { id: TocItem.overview.id.to_s },  data_type_id: DataType.text.id.to_s,
               object_title: "title", language_id: Language.english.id.to_s,
               description: "text" }
      post :create, { taxon_id: @taxon_concept.id,
                      data_object: dato },{ user: @user }
      dato[:object_title] = 'different title'
      dato[:description] = 'different description'
       post :create, { taxon_id: @taxon_concept.id,
                      data_object: dato },{ user: @user, user_id: @user.id }
      expect(response.status).to eq(301)
    end
  end

  describe 'GET edit' do
    it 'should not allow access to user who do not own the users data object' do
      another_user = User.gen()
      get :edit, { :id => @udo.id }, { :user => another_user, :user_id => another_user.id }
      flash[:error].should == I18n.t('exceptions.security_violations.default')
    end
    it 'should only render edit users data object of data type text and owned by current user' do
      get :edit, { :id => @udo.id }, { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      response.should render_template('data_objects/edit')
    end
  end

  describe 'PUT update' do
    it 'should re-render edit if validation fails' do
      put :update, { :id => @udo.id,
                     :data_object => { :rights_holder => @user.full_name, :source_url => "", :rights_statement => "",
                                       :toc_items => { :id => @udo.toc_items.first.id.to_s }, :bibliographic_citation => "",
                                       :data_type_id => DataType.text.id.to_s, :object_title =>"test_master",
                                       :description => "", :license_id => License.public_domain.id.to_s },
                                       :language_id => Language.english.id.to_s },
                   { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      response.should render_template('data_objects/edit')
    end
    it 'should create a new data object revision'
  end

  describe 'GET crop' do
    before(:each) do
      @image = DataObject.gen(:data_type_id => DataType.image.id, :object_cache_url => FactoryGirl.generate(:image))
    end

    it 'should not allow access to non-curators' do
      get :crop, { :id => @image.id }
      response.should redirect_to(login_url)

      expect { get :crop, { :id => @image.id }, { :user => @user, :user_id => @user.id } }.
        to raise_error(EOL::Exceptions::SecurityViolation) {|e| e.flash_error_key.should == :min_assistant_curators_only}
    end

    it 'should allow access to curators' do
      curator = build_curator(TaxonConcept.gen, :level => :assistant)
      original_object_cache_url = @image.object_cache_url
      new_object_cache_url = FactoryGirl.generate(:image)
      new_object_cache_url.should_not == original_object_cache_url
      @image.object_cache_url.should == original_object_cache_url
      ContentServer.should_receive(:update_data_object_crop).and_return(new_object_cache_url)
      get :crop, { :id => @image.id, :x => 0, :y => 0, :w => 1 }, { :user => curator, :user_id => curator.id }
      @image.reload
      @image.object_cache_url.should == new_object_cache_url
      response.should redirect_to(data_object_path(@image))
      flash[:notice].should == "Image was cropped successfully."
    end
  end
  
  describe 'GET reindex' do 
    before(:all) do
      @dato = DataObject.gen(data_type_id: DataType.image.id, object_cache_url: FactoryGirl.generate(:image))
    end

    context 'allows reindexing' do 
      it 'allows access to admins' do
        admin = User.gen
        admin.grant_admin
        get :reindex, {id: @dato.id}, {user: admin,  user_id: admin.id }
        expect(flash[:notice]).to eq(I18n.t(:this_data_object_will_be_reindexed))
      end

      it 'allows access to master curators' do
        master_curator = build_curator(@taxon_concept, level: :master)
        expect(master_curator.min_curator_level?(:master)).to be_true
        get :reindex, {id: @dato.id}, {user: master_curator,  user_id: master_curator.id }
        expect(flash[:notice]).to eq(I18n.t(:this_data_object_will_be_reindexed))
      end
    end
    
   context 'does not allow reindexing' do 
     it 'does not allow access to non-master curators/non-admins' do
       expect{get :reindex, {id: @dato.id}, {user: @user, user_id: @user.id}}.to raise_error
     end
    end
  end
end
