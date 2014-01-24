require File.dirname(__FILE__) + '/../spec_helper'

describe 'Feeds' do

  def verify_entry_for_object(xpath_object)
    xpath_object.xpath("xmlns:id").inner_text.should == data_object_url(@data_object)
    xpath_object.xpath("xmlns:link[@rel='alternate']/@href").inner_text.should == data_object_url(@data_object)
    xpath_object.xpath("xmlns:title").inner_text.should == @data_object.first_hierarchy_entry.name.string
  end

  before(:all) do
    load_foundation_cache
    @user = User.gen(curator_level: CuratorLevel.full, credentials: 'whatever', curator_scope: 'fun')
    # creating bits we need for the content partner/resource/harvest
    @agent = Agent.gen(full_name: 'HierarchyAgent')
    @hierarchy = Hierarchy.gen(label: 'TreeofLife', description: 'contains all life', agent: @agent)
    @hierarchy_entry = HierarchyEntry.gen(hierarchy: @hierarchy)
    @resource_user = User.gen(agent: @agent)
    @content_partner = ContentPartner.gen(user: @resource_user)
    @resource = Resource.gen(title: "FishBase Resource", content_partner: @content_partner)
    @harvest_event = HarvestEvent.gen(resource_id: @resource.id, published_at: Time.now)
    @taxon_concept = TaxonConcept.gen(published: 1, supercedure_id: 0)
    @hierarchy_entry = HierarchyEntry.gen(taxon_concept_id: @taxon_concept.id)
    HarvestEventsHierarchyEntry.gen(hierarchy_entry_id: @hierarchy_entry.id, harvest_event_id: @harvest_event.id)
    @misidentified = UntrustReason.misidentified
    @user_regex = "by.*#{user_url(@user)}.*#{@user.full_name}.*last [0-9].*at [0-9]{2}:"
  end

  before(:each) do
    CuratorActivityLog.destroy_all
    @data_object = build_data_object("Text", "This is a description", published: 1, vetted: Vetted.trusted)
    DataObjectsHarvestEvent.gen(data_object_id: @data_object.id, harvest_event_id: @harvest_event.id, guid: @data_object.guid)
    DataObjectsHierarchyEntry.delete_all(data_object_id: @data_object.id, hierarchy_entry_id: @hierarchy_entry.id)
    @dohe = DataObjectsHierarchyEntry.create(data_object: @data_object, hierarchy_entry: @hierarchy_entry,
                                                    visibility: Visibility.visible, vetted: Vetted.trusted)
    @association = DataObjectTaxon.new(@dohe)
  end

  it 'should start with an empty feed' do
    url = partner_curation_feeds_url(content_partner_id: @content_partner.id, year: Time.now.year)
    response = get_as_xml(url)
    response.xpath('//xmlns:feed/xmlns:id').inner_text.should == url
    response.xpath('//xmlns:feed/xmlns:link[@rel="alternate"]/@href').inner_text.should == root_url
    response.xpath('//xmlns:feed/xmlns:link[@rel="self"]/@href').inner_text.should == url
    response.xpath('//xmlns:feed/xmlns:updated').length.should == 1
    response.xpath('//xmlns:feed/xmlns:title').inner_text.should == @content_partner.full_name + ' curation activity'
    response.xpath('//xmlns:feed/xmlns:entry').length.should == 0
  end

  it 'should list untrusting actions' do
    Curation.curate(
      user: @user,
      association: @association,
      vetted: Vetted.untrusted,
      untrust_reason_ids: [ @misidentified.id ]
    )
    url = partner_curation_feeds_url(content_partner_id: @content_partner.id, year: Time.now.year)
    response = get_as_xml(url)
    response.xpath('//xmlns:feed/xmlns:entry').length.should == 2
    verify_entry_for_object(response.xpath('//xmlns:feed/xmlns:entry[1]'))
    verify_entry_for_object(response.xpath('//xmlns:feed/xmlns:entry[2]'))
    response.xpath('//xmlns:feed/xmlns:entry[1]/xmlns:content').inner_text.should match /Hide #{@user_regex}/
    response.xpath('//xmlns:feed/xmlns:entry[2]/xmlns:content').inner_text.should match /Untrusted #{@user_regex}/
  end

  it 'should list trusting actions' do
    @dohe.vetted = Vetted.unknown
    @dohe.visibility = Visibility.invisible
    @dohe.save
    Curation.curate(
      user: @user,
      association: DataObjectTaxon.new(@dohe),
      vetted: Vetted.trusted,
      visibility: Visibility.visible
    )
    url = partner_curation_feeds_url(content_partner_id: @content_partner.id, year: Time.now.year)
    response = get_as_xml(url)
    response.xpath('//xmlns:feed/xmlns:entry').length.should == 2
    verify_entry_for_object(response.xpath('//xmlns:feed/xmlns:entry[1]'))
    verify_entry_for_object(response.xpath('//xmlns:feed/xmlns:entry[2]'))
    response.xpath('//xmlns:feed/xmlns:entry[1]/xmlns:content').inner_text.should match /Show #{@user_regex}/
    response.xpath('//xmlns:feed/xmlns:entry[2]/xmlns:content').inner_text.should match /Trusted #{@user_regex}/
  end

end
