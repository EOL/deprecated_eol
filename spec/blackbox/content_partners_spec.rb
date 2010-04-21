require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partners' do

  Scenario.load :foundation

  it 'home page of EOL should have desc-personal tag with "Hello [full_name]" and a logout link when logged in' do
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

  it 'content partner home page should have cp-desc-personal tag with "Welcome [full_name]" and a logout link when logged in' do
    pass  = 'timey-wimey'
    agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(pass))
    cp    = ContentPartner.gen(:agent => agent)
    login_content_partner(:username => agent.username, :password => pass)
    body  = request('/content_partner').body
    body.should have_tag('div#cp-desc-personal', :text => /Welcome ?\s+#{agent.full_name}/) do
      with_tag('a[href*=?]', /logout/)
    end
  end
  
  it 'content partner should have a gallery' do
    agent = Agent.gen(:full_name => 'gallery_test_agent')
    cp = ContentPartner.gen(:agent => agent)
    image = build_data_object('Image', "the image description", :content_partner => cp)
    
    # the data_object builder doesn't properly associate the image's taxon with the resource, so that's done here
    cp.agent.resources[0].harvest_events.each do |he|
      he.taxa << image.taxa[0]
    end
    body = request("/content_partner/content/#{cp.agent.full_name}").body
    body.should have_tag('div#content_partner_stats', :text => /#{cp.agent.full_name}\s+has contributed to a total of\s+1\s+pages/)
    body.should include("pages/#{image.taxa[0].hierarchy_entry.taxon_concept.id}")
  end


end
