# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:synonyms' do
  before(:all) do
    load_foundation_cache
    # DataObjects
    @overview_text   = 'This is a test Overview, in all its glory'
    @distribution      = TocItem.gen_if_not_exists(label: 'Ecology and Distribution')
    @distribution_text = 'This is a test Distribution'
    @description       = TocItem.gen_if_not_exists(label: 'Description')
    @description_text  = 'This is a test Description, in all its glory'
    @toc_item_2      = TocItem.gen(view_order: 2)
    @toc_item_3      = TocItem.gen(view_order: 3)

    @taxon_concept   = build_taxon_concept(
       flash:           [{description: 'First Test Video'}, {description: 'Second Test Video'}],
       youtube:         [{description: 'YouTube Test Video'}],
       images:          [{object_cache_url: FactoryGirl.generate(:image)}, {object_cache_url: FactoryGirl.generate(:image)},
                          {object_cache_url: FactoryGirl.generate(:image)}],
       toc:             [{toc_item: TocItem.overview, description: @overview_text, license: License.by_nc, rights_holder: "Someone"},
                          {toc_item: @distribution, description: @distribution_text, license: License.cc, rights_holder: "Someone"},
                          {toc_item: @description, description: @description_text, license: License.public_domain, rights_holder: ""},
                          {toc_item: @description, description: 'test uknown', vetted: Vetted.unknown, license: License.by_nc, rights_holder: "Someone"},
                          {toc_item: @description, description: 'test untrusted', vetted: Vetted.untrusted, license: License.cc, rights_holder: "Someone"}])
    @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, agent: Agent.last, language: Language.english)
    @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, agent: Agent.last, language: Language.english)

    d = DataObject.last
    d.license = License.by_nc
    d.save!
    @object = DataObject.create(
      guid:                   '803e5930803396d4f00e9205b6b2bf21',
      identifier:             'doid',
      data_type:              DataType.text,
      mime_type:              MimeType.gen_if_not_exists(label: 'text/html'),
      object_title:           'default title',
      language:               Language.find_or_create_by_iso_639_1('en'),
      license:                License.by_nc,
      rights_statement:       'default rights © statement',
      rights_holder:          'default rights holder',
      bibliographic_citation: 'default citation',
      source_url:             'http://example.com/12345',
      description:            'default description <a href="http://www.eol.org">with some html</a>',
      object_url:             '',
      thumbnail_url:          '',
      location:               'default location',
      latitude:               1.234,
      longitude:              12.34,
      altitude:               123.4,
      published:              1,
      curated:                0)
    @object.info_items << InfoItem.gen_if_not_exists(label: 'Distribution')
    @object.save!

    AgentsDataObject.create(data_object_id: @object.id,
                            agent_id: Agent.gen(full_name: 'agent one', homepage: 'http://homepage.com/?agent=one&profile=1').id,
                            agent_role: AgentRole.writer,
                            view_order: 1)
    AgentsDataObject.create(data_object_id: @object.id,
                            agent: Agent.gen(full_name: 'agent two'),
                            agent_role: AgentRole.editor,
                            view_order: 2)
    @object.refs << Ref.gen(full_reference: 'first reference')
    @object.refs << Ref.gen(full_reference: 'second reference')
    @taxon_concept.add_data_object(@object)
  end

  it 'should create an API log including API key' do
    user = User.gen(api_key: User.generate_key)
    check_api_key("/api/data_objects/#{@object.guid}?key=#{user.api_key}", user)
  end

  it "data objects should show unpublished objects" do
    @object.update_column(:published, 0)
    response = get_as_xml("/api/data_objects/#{@object.guid}")
    response.xpath('/').inner_html.should_not == ""
    response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == @object.guid
    @object.update_column(:published, 1)
  end

  it "data objects should show a taxon element for the data object request" do
    response = get_as_xml("/api/data_objects/#{@object.guid}")
    response.xpath('/').inner_html.should_not == ""
    response.xpath('//xmlns:taxon/dc:identifier').inner_text.should == @object.get_taxon_concepts(published: :strict)[0].id.to_s
  end
  
  it "data objects should show exemplar info for taxon concept for the data object request" do
    TaxonConceptExemplarArticle.gen(data_object: @object, taxon_concept: @taxon_concept)
    response = get_as_xml("/api/data_objects/#{@object.guid}")
    response.xpath('//xmlns:taxon/dwc:exemplar').inner_text.should == "true"
  end

  it "data objects should show all information for text objects" do
    response = get_as_xml("/api/data_objects/#{@object.guid}")
    response.xpath('/').inner_html.should_not == ""
    response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == @object.guid
    response.xpath('//xmlns:dataObject/xmlns:dataType').inner_text.should == @object.data_type.schema_value
    response.xpath('//xmlns:dataObject/xmlns:mimeType').inner_text.should == @object.mime_type.label
    response.xpath('//xmlns:dataObject/dc:title').inner_text.should == @object.object_title
    response.xpath('//xmlns:dataObject/dc:language').inner_text.should == @object.language.iso_639_1
    response.xpath('//xmlns:dataObject/xmlns:license').inner_text.should == @object.license.source_url
    response.xpath('//xmlns:dataObject/dc:rights').inner_text.should == @object.rights_statement_for_display
    response.xpath('//xmlns:dataObject/dcterms:rightsHolder').inner_text.should == @object.rights_holder_for_display
    response.xpath('//xmlns:dataObject/dcterms:bibliographicCitation').inner_text.should == @object.bibliographic_citation_for_display
    response.xpath('//xmlns:dataObject/dc:source').inner_text.should == @object.source_url
    response.xpath('//xmlns:dataObject/xmlns:subject').inner_text.should == @object.info_items[0].schema_value
    response.xpath('//xmlns:dataObject/dc:description').inner_text.should == @object.description
    response.xpath('//xmlns:dataObject/xmlns:location').inner_text.should == @object.location
    response.xpath('//xmlns:dataObject/geo:Point/geo:lat').inner_text.should == @object.latitude.to_s
    response.xpath('//xmlns:dataObject/geo:Point/geo:long').inner_text.should == @object.longitude.to_s
    response.xpath('//xmlns:dataObject/geo:Point/geo:alt').inner_text.should == @object.altitude.to_s

    # testing agents
    response.xpath('//xmlns:dataObject/xmlns:agent').length.should == 2
    response.xpath('//xmlns:dataObject/xmlns:agent[1]').inner_text.should == @object.agents[0].full_name
    response.xpath('//xmlns:dataObject/xmlns:agent[1]/@homepage').inner_text.should == @object.agents[0].homepage
    response.xpath('//xmlns:dataObject/xmlns:agent[1]/@role').inner_text.should == @object.agents_data_objects[0].agent_role.label.downcase
    response.xpath('//xmlns:dataObject/xmlns:agent[2]').inner_text.should == @object.agents[1].full_name
    response.xpath('//xmlns:dataObject/xmlns:agent[2]/@role').inner_text.should == @object.agents_data_objects[1].agent_role.label.downcase

    #testing references
    response.xpath('//xmlns:dataObject/xmlns:reference').length.should == 2
    response.xpath('//xmlns:dataObject/xmlns:reference[1]').inner_text.should == @object.refs[0].full_reference
    response.xpath('//xmlns:dataObject/xmlns:reference[2]').inner_text.should == @object.refs[1].full_reference
  end

  it 'data objects should be able to render a JSON response' do
    response = get_as_json("/api/data_objects/#{@object.guid}.json")
    response.class.should == Hash
    response['dataObjects'][0]['identifier'].should == @object.guid
    response['dataObjects'][0]['dataType'].should == @object.data_type.schema_value
    response['dataObjects'][0]['mimeType'].should == @object.mime_type.label
    response['dataObjects'][0]['title'].should == @object.object_title
    response['dataObjects'][0]['language'].should == @object.language.iso_639_1
    response['dataObjects'][0]['license'].should == @object.license.source_url
    response['dataObjects'][0]['rights'].should == @object.rights_statement_for_display
    response['dataObjects'][0]['rightsHolder'].should == @object.rights_holder_for_display
    response['dataObjects'][0]['bibliographicCitation'].should == @object.bibliographic_citation_for_display
    response['dataObjects'][0]['source'].should == @object.source_url
    response['dataObjects'][0]['subject'].should == @object.info_items[0].schema_value
    response['dataObjects'][0]['description'].should == @object.description
    response['dataObjects'][0]['location'].should == @object.location
    response['dataObjects'][0]['latitude'].should == @object.latitude
    response['dataObjects'][0]['longitude'].should == @object.longitude
    response['dataObjects'][0]['altitude'].should == @object.altitude

    # testing agents
    response['dataObjects'][0]['agents'].length.should == 2

    #testing references
    response['dataObjects'][0]['references'].length.should == 2
  end

  it "data objects should show all information for image objects" do
    tc = build_taxon_concept
    images = tc.data_objects.delete_if{|d| d.data_type_id != DataType.image.id}
    image = images.last
    image.data_type = DataType.image
    image.mime_type = MimeType.gen_if_not_exists(label: 'image/jpeg')
    image.object_url = 'http://images.marinespecies.org/resized/23745_electra-crustulenta-pallas-1766.jpg'
    image.object_cache_url = 200911302039366
    image.save!

    response = get_as_xml("/api/data_objects/#{image.guid}")
    response.xpath('/').inner_html.should_not == ""
    response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == image.guid
    response.xpath('//xmlns:dataObject/xmlns:dataType').inner_text.should == image.data_type.schema_value
    response.xpath('//xmlns:dataObject/xmlns:mimeType').inner_text.should == image.mime_type.label

    #testing images
    response.xpath('//xmlns:dataObject/xmlns:mediaURL').length.should == 2
    response.xpath('//xmlns:dataObject/xmlns:mediaURL[1]').inner_text.should == image.object_url
    response.xpath('//xmlns:dataObject/xmlns:mediaURL[2]').inner_text.gsub(/\//, '').should include(image.object_cache_url.to_s)
  end

  it 'data objects should be able to toggle common names' do
    visit("/api/data_objects/#{@object.guid}")
    source.should_not include '<commonName'

    visit("/api/data_objects/#{@object.guid}?common_names=1")
    source.should include '<commonName'
  end

  it 'should ' do
    curator = build_curator(@taxon_concept, level: :full)
    second_taxon_concept = build_taxon_concept
    d = DataObject.gen
    d.add_curated_association(curator, @taxon_concept.entry)
    d.add_curated_association(curator, second_taxon_concept.entry)
    # checking initial state
    response = get_as_json("/api/data_objects/#{d.guid}.json")
    response['identifier'].should == @taxon_concept.id
    # show exemplar info about taxon
    response['exemplar'].should == false
    # cfirst taxon is invisible, so second taxon is chosen
    d.curated_data_objects_hierarchy_entries.first.update_column(:visibility_id, Visibility.invisible.id)
    response = get_as_json("/api/data_objects/#{d.guid}.json")
    response['identifier'].should == second_taxon_concept.id
    # checking initial state is restored
    d.curated_data_objects_hierarchy_entries.first.update_column(:visibility_id, Visibility.visible.id)
    response = get_as_json("/api/data_objects/#{d.guid}.json")
    response['identifier'].should == @taxon_concept.id
    # first taxon is untrusted, so second taxon is chosen
    d.curated_data_objects_hierarchy_entries.first.update_column(:vetted_id, Vetted.untrusted.id)
    response = get_as_json("/api/data_objects/#{d.guid}.json")
    response['identifier'].should == second_taxon_concept.id
    # one taxon is untrusted, the other invisible, so we will get none back
    d.curated_data_objects_hierarchy_entries[1].update_column(:visibility_id, Visibility.invisible.id)
    response = get_as_json("/api/data_objects/#{d.guid}.json")
    response['identifier'].should == nil
  end

  describe 'adding crop fields to images' do

    context'displaying in XML format' do
      it 'adds crop information for images' do
        image= DataObject.gen(data_type_id: DataType.image.id)
        @taxon_concept.add_data_object(image)
        ImageSize.create(data_object_id: image.id, height: 10,
                         width:10, crop_x_pct: 10, crop_y_pct: 10,
                         crop_width_pct: 10, crop_height_pct: 10)
        response= get_as_xml("/api/data_objects/#{image.guid}")
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:height').inner_text).to eq(image.image_size.height.to_s)
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:width').inner_text).to eq(image.image_size.width.to_s)
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_x').inner_text).to eq((image.image_size.crop_x_pct * image.image_size.width / 100.0).to_s)
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_y').inner_text).to eq((image.image_size.crop_y_pct * image.image_size.height / 100.0).to_s)
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_height').inner_text).to eq((image.image_size.crop_height_pct * image.image_size.height / 100.0).to_s)
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_width').inner_text).to eq((image.image_size.crop_width_pct * image.image_size.width / 100.0).to_s)
      end

      it 'does not add info for blank data' do 
        image= DataObject.gen(data_type_id: DataType.image.id)
        @taxon_concept.add_data_object(image)
        response= get_as_xml("/api/data_objects/#{image.guid}")
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:height').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:width').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_x').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_y').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_width').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_width').inner_text).to be_blank
      end

      it 'does not add info for other data objects' do
        response= get_as_xml("/api/data_objects/#{@object.guid}")
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:height').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:width').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_x').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_y').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_width').inner_text).to be_blank
        expect(response.xpath('//xmlns:dataObject/xmlns:additionalInformation/xmlns:crop_width').inner_text).to be_blank
      end
    end

    context'displaying in JSON format' do
      it 'adds crop information for images' do
        image= DataObject.gen(data_type_id: DataType.image.id)
        @taxon_concept.add_data_object(image)
        ImageSize.create(data_object_id: image.id, height: 10,
                         width:10, crop_x_pct: 10, crop_y_pct: 10,
                         crop_width_pct: 10, crop_height_pct: 10)
        response= get_as_json("/api/data_objects/#{image.guid}.json")
        expect(response['dataObjects'][0]['height']).to eq(image.image_size.height)
        expect(response['dataObjects'][0]['width']).to eq(image.image_size.width)
        expect(response['dataObjects'][0]['crop_x'].to_s).to eq((image.image_size.crop_x_pct * image.image_size.width / 100.0).to_s)
        expect(response['dataObjects'][0]['crop_y'].to_s).to eq((image.image_size.crop_y_pct * image.image_size.height / 100.0).to_s)
        expect(response['dataObjects'][0]['crop_height'].to_s).to eq((image.image_size.crop_height_pct * image.image_size.height / 100.0).to_s)
        expect(response['dataObjects'][0]['crop_width'].to_s).to eq((image.image_size.crop_width_pct * image.image_size.width / 100.0).to_s)
      end

      it 'does not add info for blank data' do 
        image= DataObject.gen(data_type_id: DataType.image.id)
        @taxon_concept.add_data_object(image)
        response= get_as_json("/api/data_objects/#{image.guid}.json")
        puts response['dataObjects']  
        expect(response['dataObjects'][0]['height']).to be_blank
        expect(response['dataObjects'][0]['width']).to be_blank
        expect(response['dataObjects'][0]['crop_x']).to be_blank
        expect(response['dataObjects'][0]['crop_y']).to be_blank
        expect(response['dataObjects'][0]['crop_width']).to be_blank
        expect(response['dataObjects'][0]['crop_width']).to be_blank
      end

      it 'does not add info for other data objects' do
        response= get_as_json("/api/data_objects/#{@object.guid}.json")
        expect(response['dataObjects'][0]['height']).to be_blank
        expect(response['dataObjects'][0]['width']).to be_blank
        expect(response['dataObjects'][0]['crop_x']).to be_blank
        expect(response['dataObjects'][0]['crop_y']).to be_blank
        expect(response['dataObjects'][0]['crop_width']).to be_blank
        expect(response['dataObjects'][0]['crop_width']).to be_blank
      end
    end
  end
end
