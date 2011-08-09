require File.dirname(__FILE__) + '/../spec_helper'

describe "Content Partner Taxa Comments" do

# WIP

#  before(:all) do
#    truncate_all_tables
#    load_foundation_cache
#    Capybara.reset_sessions!
#    @user = User.gen(:username => 'anything')
#    @user.password = 'whatevs'
#    @user.save
#
#    @content_partner = ContentPartner.gen(:user => @user)
#    @resource = Resource.gen(:title => "test resource", :content_partner => @content_partner)
#    last_month = Time.now - 1.month
#    @harvest_event = HarvestEvent.gen(:resource_id => @resource.id, :published_at => last_month, :completed_at => last_month)
#    @taxon_concept = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
#    @hierarchy_entry = HierarchyEntry.gen(:taxon_concept_id => @taxon_concept.id)
#    @harvest_event_hierarchy_entry = HarvestEventsHierarchyEntry.gen(:harvest_event_id => @harvest_event.id, :hierarchy_entry_id => @hierarchy_entry.id, :status_id => 1)
#    @comment = Comment.gen(:parent_id => @taxon_concept.id, :parent_type => 'TaxonConcept', :user_id => @user.id, :body => "Comment for the taxon", :created_at => last_month, :visible_at => last_month)
#  end
#
#  after(:all) do
#    truncate_all_tables
#  end
#
#  before(:each) do
#    login_as(@user)
#  end
#
#  after(:each) do
#    visit('/logout')
#  end
#
#  it "should render taxa comments page" do
#    visit("/content_partner/reports/taxa_comments_report")
#    body.should include "Comments on Taxa"
#    body.should include @comment.body
#    body.should include @taxon_concept.quick_scientific_name
#    body.should include @user.username
#  end

end
