require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password
  User.gen :username => username, :password => password
end

describe 'User Profile' do


  before(:all) do
    Scenario.load :foundation
    @username = 'userprofilespec'
    @password = 'beforeall'
    @user     = create_user(@username, @password)
    
    @settings_body = RackBox.request('/settings').body
    login_as @user
    @profile_body = RackBox.request('/settings').body # Aaaaactually, this will probably fail 'cause it needs https
  end

  it 'should allow change of filter content hierarchy' do
    @settings_body.should include('Filter EOL')
    @settings_body.should have_tag('input#user_filter_content_by_hierarchy')
    @profile_body.should include('Filter EOL')
    @profile_body.should have_tag('input#user_filter_content_by_hierarchy')
  end

end
