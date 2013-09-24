require File.dirname(__FILE__) + '/../spec_helper'

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
      TocItem.gen_if_not_exists(:label => 'overview')
      post :create, { :taxon_id => 1, :references => "Test reference.",
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
      TocItem.gen_if_not_exists(:label => 'overview')
      post :create, { :taxon_id => 1, :commit_link => true,
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
      TocItem.gen_if_not_exists(:label => 'overview')
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
        to raise_error(EOL::Exceptions::SecurityViolation) {|e| e.flash_error_key.should == "min_assistant_curators_only"}
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
end
