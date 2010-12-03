require File.dirname(__FILE__) + '/../spec_helper'

describe 'Login' do
  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
  end
  
  after :all do 
    truncate_all_tables
  end
  
  after :each do
    visit('/logout')
  end
  
  it 'login page should render OK' do
    visit('/login')
    body.should have_tag('form[action="/account/authenticate"]') do
      with_tag('input#user_username')
      with_tag('input#user_password')
    end
  end
  
  it 'should redirect us back to login if we logged in incorrectly' do
    login_as :username => 'snoopy', :password => 'wrongtotallywrong'
    #submitting a wrong password shold redirect to the login page
    current_path.should == '/login'
  end

  it 'should tell us if we logged in incorrectly' do
    # first, we fail a login attempt
    login_as( :username => 'snoopy', :password => 'wrongtotallywrong')
    body.should include('Invalid login')
  end

  it 'should redirect to index after a successful login' do
    user = User.gen :username => 'johndoe'
    login_as(user)
    current_path.should == root_path
  end
 
  it 'should set a remember token for us if we asked to be remembered' do
    user = User.gen :username => 'charliebrown'
    login_as(user, :remember_me => '1')
    current_path.should == root_path
    user.reload.remember_token.should_not be_blank
  end

  it 'should say hello to the user after logging in' do
    user = User.gen :username => 'charliebrown'
    visit('/')
    body.should_not include_text("Hello #{ user.given_name }")
    login_as(user)
    visit('/')
    body.should include_text("Hello #{ user.given_name }")
  end
  
  it 'should be able to logout user' do 
    user = User.gen :username => 'johndoe'
    greetings = "Hello #{user.given_name}" 
    login_as(user) 
    visit('/')
    body.should have_tag('div.desc-personal') do
      with_tag('p', :text => /#{greetings}/)
    end
    visit('/logout')
    visit('/')
    body.should_not have_tag('p', :text => /#{greetings}/)
  end
  
  it 'should not show the curator link and name must not have hyperlink to profile page' do
    user = User.gen :username => 'charliebrown'
    login_as(user)
    visit('/')
    body.should_not include_text('curators')
    body.should_not include_text("/account/show/")
  end

  describe "as a curator" do

    it "should show the curator link and name must have hyperlink to profile page" do
      curator = build_curator(HierarchyEntry.gen, :username => 'test_curator')
      login_as(curator)
      body.should include_text("curators")
      body.should include_text("/account/show/")
    end
  end

end

