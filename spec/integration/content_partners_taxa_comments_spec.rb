require File.dirname(__FILE__) + '/../spec_helper'

describe "Content Partner Taxa Comments" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @tc = build_taxon_concept
    @pass  = 'timey-wimey'
    @agent = Agent.gen(:hashed_password => Digest::MD5.hexdigest(@pass))
    @cp    = ContentPartner.gen(:agent => @agent)


    @user = User.gen();
    @resource = Resource.gen(:title => "test resource")
    @agent_resource = AgentsResource.gen(:agent_id => @agent.id, :resource_id => @resource.id)
    last_month = Time.now - 1.month      
    @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month, :completed_at => last_month)
    @taxon_concept = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
    @hierarchy_entry = HierarchyEntry.gen(:taxon_concept_id => @taxon_concept.id)
    @harvest_event_hierarchy_entry = HarvestEventsHierarchyEntry.gen(:harvest_event_id => @harvest_event.id, :hierarchy_entry_id => @hierarchy_entry.id, :status_id => 1)
    @comment = Comment.gen(:parent_id => @taxon_concept.id, :parent_type => 'TaxonConcept', :user_id => @user.id, :body => "Comment for the taxon", :created_at => last_month, :visible_at => last_month)
    @action_history = ActionsHistory.gen(:object_id => @comment.id, :changeable_object_type_id => ChangeableObjectType.find_by_ch_object_type('comment').id, :user_id => @user.id)            
  end

  after(:all) do
    truncate_all_tables
  end

  after(:each) do
    visit("/content_partner/logout")
  end
  
  it "should show content partner page" do
    login_content_partner_capybara(:username => @agent.username, :password => @pass)
    visit('/content_partner')
    body.should include "Hello"
  end
  
  it "should render taxa comments page" do
    login_content_partner_capybara(:username => @agent.username, :password => @pass)    
    visit("/content_partner/reports/taxa_comments_report")
    body.should include "Comments on Taxa"
    body.should include @comment.body
    body.should include @action_history.taxon_concept_name    
    body.should include @action_history.comment_object.parent_type_name
  end  
  
end
