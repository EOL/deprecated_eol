require File.dirname(__FILE__) + '/../spec_helper'

def data_object_create_edit_variables_should_be_assigned
  assigns[:data_object].should be_a(DataObject)
  assigns[:toc_items].first.should be_a(TocItem)
  assigns[:toc_items].select{|ti| ti.id == assigns[:selected_toc_item_id]}.first.should be_a(TocItem)
  assigns[:languages].first.should be_a(Language)
  assigns[:licenses].first.should be_a(License)
  assigns[:page_title].should be_a(String)
  assigns[:page_description].should be_a(String)
end

describe DataObjectsController do
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @taxon_concept = TaxonConcept.gen
    @user = User.gen
    @udo = @taxon_concept.add_user_submitted_text(:user => @user)
  end

  # GET /pages/:taxon_id/data_objects/new
  describe 'GET new' do
    it 'should render new if logged in' do
      get :new, { :taxon_id => @taxon_concept.id } # not logged in
      response.rendered[:template].should be_nil
      response.redirected_to.should =~ /login/
      get :new, { :taxon_id => @taxon_concept.id }, { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      assigns[:data_object].new_record?.should be_true
      response.rendered[:template].should == 'data_objects/new.html.haml'
    end
  end

  describe 'POST create' do
    it 'should instantiate references' do
      TocItem.gen_if_not_exists(:label => 'overview')
      post :create, { :taxon_id => 1,
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.text.id.to_s,
                                        :references => "Test reference.", :object_title => "Test Article",
                                        :description => "Test text", :license_id => License.public_domain.id.to_s,
                                        :language_id => Language.english.id.to_s } },
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
      response.rendered[:template].should == 'data_objects/new.html.haml'
    end
    it 'should only create users data object of data type text' do
      post :create, { :taxon_id => @taxon_concept.id,
                      :data_object => { :toc_items => { :id => TocItem.overview.id.to_s }, :data_type_id => DataType.image.id.to_s,
                                        :object_title => "Test Article", :description => "Test text" } },
                    { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      response.rendered[:template].should == 'data_objects/new.html.haml'
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
      response.rendered[:template].should == 'data_objects/edit.html.haml'
    end
  end

  describe 'PUT update' do
    it 'should re-render edit if validation fails' do
      TocItem.gen_if_not_exists(:label => 'overview')
      put :update, { :id => @udo.id,
                     :data_object => { :rights_holder => @user.full_name, :source_url => "", :rights_statement => "",
                                       :toc_items => { :id => @udo.toc_items.first.id.to_s }, :bibliographic_citation => "",
                                       :data_type_id => DataType.text.id.to_s, :references => "", :object_title =>"test_master",
                                       :description => "", :license_id => License.public_domain.id.to_s },
                                       :language_id => Language.english.id.to_s },
                   { :user => @user, :user_id => @user.id }
      data_object_create_edit_variables_should_be_assigned
      response.rendered[:template].should == 'data_objects/edit.html.haml'
    end
    it 'should create a new data object revision'
  end
end