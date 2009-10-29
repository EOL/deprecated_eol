require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password, args = {}
  User.gen({:username => username, :password => password}.merge(args))
end

# NOTE !!!!!!!
#
# I crippled this file, temporarily, in order to commit fixes elsewhere in the suite.

describe 'User Profile' do

  Scenario.load :foundation

  before(:all) do
    @username  = 'bobbafett'
    @password  = 'ihatesolo'
    @filter    = false
    @switch_to = true
    @tag       = 'input#user_filter_content_by_hierarchy'
    @user      = create_user(@username, @password, :filter_content_by_hierarchy => @filter)
    @settings_body = request('/settings').body
    login_as(@user).should redirect_to('/')
    @profile_body = request('/settings').body
  end

  it 'should allow change of filter content hierarchy' do
    @settings_body.should include('browse classification')
    @settings_body.should have_tag(@tag)
    @profile_body.should include('browse classification')
    @profile_body.should have_tag(@tag)
  end

  it 'should keep a change of value for filter content hierarchy' do
    request('/settings',
            :params => { 
              'user[filter_content_by_hierarchy]' => @switch_to })
    request('/settings').body.should have_tag("#{@tag}[checked=?]", 'checked')
  end

end
