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
    it 'should re-render new if model validation fails' # do
#      post :create, { :taxon_id => @taxon_concept.id,
#                      :data_object => { :title => 'Blank description will fail validation',
#                                        :description => '' } },
#                    { :user => @user, :user_id => @user.id }
#      data_object_create_edit_variables_should_be_assigned
#      response.rendered[:template].should == 'data_objects/new.html.haml'
#    end
    it 'should only create users data object of data type text'
  end

  describe 'GET edit' do
    it 'should only render edit users data object of data type text and owned by current user'
  end

  describe 'PUT update' do
    it 'should re-render edit if validation fails'
    it 'should create a new data object revision'
  end
end