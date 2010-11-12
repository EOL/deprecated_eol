require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
 curator = build_curator(tc)
 tc.images.last.curator_activity_flag curator, tc.id
 return curator
end

describe 'Curator Worklist' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    commit_transactions

    @taxon_concept = build_taxon_concept()
    @curator = create_curator_for_taxon_concept(@taxon_concept)
    @resource = Resource.gen()
    @supplier_agent = Agent.gen()
    @content_partner = ContentPartner.gen(:agent => @supplier_agent, :description => 'For testing curator worklist')
    AgentsResource.gen(:resource => @resource, :agent => @supplier_agent, :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
    @testing_harvest_event = HarvestEvent.gen(:resource => @resource)

    @ancestor_entry = @taxon_concept.hierarchy_entries[0]
    @child_entry = HierarchyEntry.gen(:parent_id => @ancestor_entry.id, :hierarchy_id => @ancestor_entry.hierarchy_id)
    @child_concept = build_taxon_concept(:id => @child_entry.taxon_concept_id, 
                        :images => [{:id => '11111', :vetted => Vetted.unknown},
                                    {:id => '11112', :vetted => Vetted.trusted}])
    @lower_child_entry = HierarchyEntry.gen(:parent_id => @child_entry.id, :hierarchy_id => @ancestor_entry.hierarchy_id)
    @lower_child_concept = build_taxon_concept(:id => @lower_child_entry.taxon_concept_id, 
                        :images => [{:id => '21113', :vetted => Vetted.unknown, :event => @testing_harvest_event},
                                    {:id => '21114', :vetted => Vetted.trusted, :event => @testing_harvest_event}])

    @first_child_unreviewed_image = DataObject.find('11111')
    @first_child_trusted_image = DataObject.find('11112')
    @lower_child_unreviewed_image = DataObject.find('21113')
    @lower_child_trusted_image = DataObject.find('21114')

    @solr = SolrAPI.new($SOLR_SERVER_DATA_OBJECTS)
    @solr.delete_all_documents
    @solr.build_data_object_index

  end

  before(:each) do
    SpeciesSchemaModel.connection.execute('set AUTOCOMMIT=1')
  end

  after(:each) do
    visit('/logout')
  end

  after(:all) do
    truncate_all_tables
  end

  it 'should show a list of unreviewed images in the curators clade' do
    login_capybara(@curator)
    visit('/curators/curate_images')
    body.should include('Curator Central')
    body.should include(@first_child_unreviewed_image.id.to_s)
    body.should include(@lower_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_trusted_image.id.to_s)
    body.should_not include(@lower_child_trusted_image.id.to_s)
  end

  it 'should be able to filter unreviewed images by hierarchy entry id' do
    login_capybara(@curator)
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}")
    body.should include('Curator Central')
    body.should include(@lower_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_trusted_image.id.to_s)
    body.should_not include(@lower_child_trusted_image.id.to_s)
  end

  it 'should be able to filter unreviewed images in the curators clade by content partner' do
    login_capybara(@curator)
    visit("/curators/curate_images?content_partner_id=#{@content_partner.id}")
    body.should include(@lower_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_trusted_image.id.to_s)
    body.should_not include(@lower_child_trusted_image.id.to_s)
  end

  it 'should be able to filter images by vetted status' do
    login_capybara(@curator)
    visit("/curators/curate_images?vetted_id=#{Vetted.trusted.id}")
    body.should include(@lower_child_trusted_image.id.to_s)
    body.should include(@first_child_trusted_image.id.to_s)
    body.should_not include(@first_child_unreviewed_image.id.to_s)
    body.should_not include(@lower_child_unreviewed_image.id.to_s)
  end

  it 'should be able to filter images by content partner and vetted status' do
    login_capybara(@curator)
    visit("/curators/curate_images?content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.trusted.id}")
    body.should include(@lower_child_trusted_image.id.to_s)
    body.should_not include(@first_child_unreviewed_image.id.to_s)
    body.should_not include(@first_child_trusted_image.id.to_s)
    body.should_not include(@lower_child_unreviewed_image.id.to_s)
  end
end
