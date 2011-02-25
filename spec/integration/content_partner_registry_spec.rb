require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partner Registry' do
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    
    @partner_password = 'doesntmatter'
    @agent = Agent.gen(:full_name => 'FishBase', :hashed_password => Digest::MD5.hexdigest(@partner_password))
    @content_partner = ContentPartner.gen(:agent => @agent)
    AgentContact.gen(:agent => @agent)
    
    @hierarchy = Hierarchy.gen(:label => 'FishBase Hierarchy', :agent => @agent)
    @resource = Resource.gen(:title => 'FishBase Resource', :subject => 'Fishes', :accesspoint_url => 'http://amphibiaweb.org/amphib_dump.xml', :hierarchy => @hierarchy)
    @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
    @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => 1.month.ago)
    @harvested_taxon_concept = build_taxon_concept(:event => @harvest_event, :hierarchy => @hierarchy)
    
    @admin = User.gen(:username => 'ourtestadmin')
    @admin.approve_to_administrate
    @admin.save!
  end
  
  
  
  describe ' : Admins' do
    before :each do
      login_as(@admin)
    end
    
    after :each do
      visit('/logout')
    end
    
    it 'should be able to view the edit resource page' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/content_partner/resources/#{@resource.id}/edit?content_partner_id=#{@agent.id}")
      body.should include("Hello #{@admin.given_name}")
      body.should include('Editing Resource')
      body.should include(@resource.accesspoint_url)
    end
    
    it 'should be able to view the harvest events' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/content_partner/resources/#{@resource.id}/harvest_events?content_partner_id=#{@agent.id}")
      body.should include("Hello #{@admin.given_name}")
      body.should include("Harvests for\n#{@agent.full_name}")
      body.should have_tag('td.odd', :text => /#{@harvest_event.id}/)
    end
    
    it 'should be able to view the taxa harvested' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/harvest_events/#{@harvest_event.id}/taxa")
      body.should include("Hello #{@admin.given_name}")
      body.should include("List of taxa harvested")
      body.should include(@harvested_taxon_concept.entry.name.canonical_form.string)
    end
    
    it 'should be able to view the resource hierarchy' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/administrator/hierarchy/browse/#{@hierarchy.id}")
      body.should include("Hello #{@admin.given_name}")
      body.should include("Hierarchy Roots:")
      body.should include("edit hierarchy")
      body.should include(@harvested_taxon_concept.entry.name.string)
    end
  end
  
  
  
  describe ' : Content Partners' do
    before :each do
      login_content_partner_capybara(:username => @agent.username, :password => @partner_password)
    end
    
    after :each do
      visit('/content_partner/logout')
    end
    
    it 'should be able to view the edit resource page' do
      visit("/content_partner/resources/#{@resource.id}/edit")
      body.should include("Hello #{@agent.full_name}")
      body.should include('Editing Resource')
      body.should include(@resource.accesspoint_url)
    end
    
    it 'should be able to view the harvest events' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/content_partner/resources/#{@resource.id}/harvest_events")
      body.should include("Hello #{@agent.full_name}")
      body.should include("Harvests for\n#{@agent.full_name}")
      body.should have_tag('td.odd', :text => /#{@harvest_event.id}/)
    end
    
    it 'should be able to view the taxa harvested' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/harvest_events/#{@harvest_event.id}/taxa")
      body.should include("Hello #{@agent.full_name}")
      body.should include("List of taxa harvested")
      body.should include(@harvested_taxon_concept.entry.name.canonical_form.string)
    end
    
    it 'should be able to view the resource hierarchy' do
      # TODO - why is it called content partner ID if it wants an agent ID?
      visit("/content_partner/hierarchy/#{@hierarchy.id}")
      body.should include("Hello #{@agent.full_name}")
      body.should include("Click to propose this hierarchy as an alternate browsing classification for EOL")
      body.should include("Hierarchy Roots:")
      body.should include(@harvested_taxon_concept.entry.name.string)
    end
  end
  
end

