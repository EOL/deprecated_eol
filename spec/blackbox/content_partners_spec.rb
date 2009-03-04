require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partners' do

  scenario :foundation

  it 'should have desc-personal tag with "Hello [full_name]" and a logout link when logged in' do
    pass  = 'timey-wimey'
    agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(pass))
    cp    = ContentPartner.gen(:agent => agent)
    login_content_partner(:username => agent.username, :password => pass)
    body  = request('/').body
    body.should have_tag('div#personal-space') do
      without_tag('a[href*=?]', /\/login/)
      with_tag('div.desc-personal', :text => /Hello,?\s+#{agent.full_name}/) do
        with_tag('a[href*=?]', /logout/)
      end
    end
  end

end
