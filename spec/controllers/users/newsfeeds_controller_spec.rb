require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::NewsfeedsController do

  before(:all) do
   load_foundation_cache
    @testy = {}
    @testy[:user] = User.gen
  end

  describe 'GET show' do

    it 'should instantiate the user' do
      get :show, :user_id => @testy[:user].id.to_i
      assigns[:user].should == @testy[:user]
    end
    it 'should know whether its a valid conversion for tracking' do
      user_id = @testy[:user].id.to_i
      get :show, { :user_id => user_id }
      assigns[:conversion].should be_nil
      conversion_code = User.generate_key
      get :show, { :user_id => user_id, :success => conversion_code }
      assigns[:conversion].should be_nil
      get :show, { :user_id => user_id }, { :success => conversion_code }
      assigns[:conversion].should be_nil
      get :show, { :user_id => user_id, :success => conversion_code },
                 { :conversion_code => conversion_code }
      assigns[:conversion].should be_a(EOL::GoogleAdWords::Conversion)
    end

    it 'should instantiate the parent property for use in a new comment' do
      get :show, :user_id => @testy[:user].id.to_i
      assigns[:parent].should == @testy[:user]
    end

  end

end
