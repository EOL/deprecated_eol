require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController do

  # Ideally these test cases should be covered by integration tests but since coverage is poor
  # unit testing is helpful to document expected behaviours of application controller methods.

  before(:all) do
    Language.gen_if_not_exists(:label => 'English')
    @taxon_name          = "<i>italic</i> foo & bar"
    @taxon_name_with_amp = "<i>italic</i> foo &amp; bar"
    @taxon_name_no_tags  = "italic foo & bar"
    @taxon_name_no_html  = "&lt;i&gt;italic&lt;/i&gt; foo &amp; bar"
  end

  it 'should have hh' do
    @controller.view_helper_methods.send(:hh, @taxon_name).should == @taxon_name_with_amp
  end

  it "should define controller action scope for translations" do
    @controller.send(:controller_action_scope).should be_a(Array)
  end

  it "should define generic parameters for translations" do
    @controller.send(:scoped_variables_for_translations).should be_a(Hash)
  end

  it "should define default meta data values" do
    @controller.send(:meta_data).should be_a(Hash)
  end

  it "should define default open graph tag values" do
    @controller.send(:meta_open_graph_data).should be_a(Hash)
  end

  it "should define default tweet data values" do
    @controller.send(:tweet_data).should be_a(Hash)
  end

  it "should store a copy of the original unmodified request params" do
    @controller.send(:original_request_params).should be_a(Hash)
  end

  describe '#logged_in?' do
    it 'should return user_id key value from session' do
      session[:user_id] = 3
      controller.logged_in?.should == 3
      session.delete(:user_id)
    end
  end

  describe '#referred_url' do
    it 'should return request referrer' do
      url = 'http://referred.url'
      request.env['HTTP_REFERER'] = url
      controller.referred_url.should == url
      request.env['HTTP_REFERER'] = nil
   end
  end

  describe '#return_to_url' do
    it 'should return return_to key value from session' do
      url = 'http://return.to.url'
      session[:return_to] = url
      controller.return_to_url.should == url
    end
  end

  describe '#redirect_back_or_default' do
    # Weird to get :redirect_back_or_default as it is not intended to be a route but we can since it is
    # a public method and we need the response from the request process for testing the redirected_to
    it 'should not redirect to login, register or logout pages when user is logged in' do
      controller.stub!(:check_user_agreed_with_terms).and_return(nil)
      [login_url, new_user_url, logout_url].each do |url|
        get :redirect_back_or_default, nil, {:user_id => 1, :return_to => url}
        response.redirected_to.should_not == url
        response.redirected_to.should == root_url
      end
    end
    it 'should remove query string from URI if query string includes oauth_provider parameter' do
      url = login_url(:oauth_provider => 'test', :another_param => 'something')
      get :redirect_back_or_default, nil, {:return_to => url}
      response.redirected_to.should == login_url
      response.redirected_to.should_not =~ /oauth_provider|another_param/
    end
    it 'should not redirect to bad URIs' do
      get :redirect_back_or_default, nil, {:return_to => {:this_is_not_a_valid => 'uri'}}
      response.redirected_to.should == root_url
      session[:return_to].should be_nil
    end
    it 'should choose session return to first' do
      valid_uri = taxon_path(1)
      get :redirect_back_or_default, nil, { :return_to => valid_uri }
      response.redirected_to.should == taxon_url(1)
      session[:return_to].should be_nil
    end
    it 'should redirect to root url when no other url is available' do
      get :redirect_back_or_default, nil, nil
      response.redirected_to.should == root_url
    end
    it 'should only redirect back to http protocols' do
      get :redirect_back_or_default, nil, {:return_to => 'https://some.url'}
      response.redirected_to.should == root_url
      session[:return_to].should be_nil
    end
  end

  describe '#access_denied' do
    # Weird to get :access_denied as its not intended to be route but we can since it is a
    # public method and we need response from request process for testing redirected_to
    it 'should redirect to referrer' do
      request.env['HTTP_REFERER'] = login_url
      get :access_denied
      response.redirected_to.should == login_url
    end
  end

end

