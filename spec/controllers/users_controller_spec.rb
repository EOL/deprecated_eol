require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    @user = User.gen
  end

  describe 'GET new'
  describe 'POST create' do
    it 'should rerender on validation errors'
    it 'should redirect on success'
    it 'should send verify email notification'
  end
  describe 'GET edit'
  describe 'PUT update' do
    it 'should rerender on validation errors'
    it 'should redirect on success'
  end

  describe 'GET terms_agreement' do

    it 'should get terms agreement' do
      TranslatedContentPage.gen(:content_page => ContentPage.gen(:page_name => 'Terms Of Use'))
      get :terms_agreement, { :id => @user.id }, { :user => @user, :user_id => @user.id }
      assigns[:user].should be_a(User)
      assigns[:terms].should be_a(TranslatedContentPage)
      response.rendered[:template].should == 'users/terms_agreement.html.haml'
    end

    it 'should force users to agree to terms before viewing other pages' do
      get :show, { :id => @user.id }, { :user => @user, :user_id => @user.id }
      response.redirected_to.should == terms_agreement_user_path(@user)
      get :edit, { :id => @user.id }, { :user => @user, :user_id => @user.id }
      response.redirected_to.should == terms_agreement_user_path(@user)
    end

    it 'should not allow users to get terms for another user' do
      user = User.gen
      get :terms_agreement, { :id => user.id } # anonymous user trying to access user terms
      response.redirected_to.should == root_url
      response.rendered[:template].should_not == 'users/terms_agreement.html.haml'
      get :terms_agreement, { :id => user.id }, { :user => @user, :user_id => @user.id }
      response.redirected_to.should == root_url
      response.rendered[:template].should_not == 'users/terms_agreement.html.haml'
    end
  end

  describe 'POST terms_agreement' do
    it 'should allow the current user to agree to terms' do
      User.find(@user).agreed_with_terms.should be_false
      post :terms_agreement, { :id => @user.id, :commit_agreed => 'I Agree' }, { :user => @user, :user_id => @user.id }
      User.find(@user).agreed_with_terms.should be_true
      response.redirected_to.should == user_path(@user)
    end

    it 'should not allow users to agree to terms for another user' do
      user = User.gen
      User.find(user).agreed_with_terms.should be_false
      post :terms_agreement, { :id => user.id }
      User.find(user).agreed_with_terms.should be_false
      response.redirected_to.should == root_url
      post :terms_agreement, { :id => user.id }, { :user => @user, :user_id => @user.id }
      User.find(user).agreed_with_terms.should be_false
      response.redirected_to.should == root_url
    end
  end


end