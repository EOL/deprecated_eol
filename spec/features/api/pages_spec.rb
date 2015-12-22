# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

# TODO - this is really awful setup.  :|

describe 'API:pages' do
  before(:all) do
    load_foundation_cache # TODO -try removing this. I think we can go faster with just create_defaults as needed.
    Capybara.reset_sessions!
    @user = User.gen(api_key: User.generate_key)

    # DataObjects
    @overview      = TocItem.overview
    @toc_item_2    = TocItem.find(TocItem.possible_overview_ids.last) # This used to be distribution
    @toc_item_3    = TocItem.find(TocItem.possible_overview_ids.second) # This used to be description
    @overview_text = 'This is a test Overview, in all its glory'
    @toc_label_2   = @toc_item_2.label
    @toc_label_3   = @toc_item_3.label
    @desc_2        = "This is a test #{@toc_label_2}"
    @desc_3        = "This is a test #{@toc_label_3}, in all its glory"
    @image_1       = FactoryGirl.generate(:image)
    @image_2       = FactoryGirl.generate(:image)
    @image_3       = FactoryGirl.generate(:image)
    @video_1_text  = 'First Test Video'
    @video_2_text  = 'Second Test Video'
    @video_3_text  = 'YouTube Test Video'

    # The API actually takes INFO ITEMS, not toc items, so let's make those if they aren't there:
    @toc_item_2.info_items << TranslatedInfoItem.gen(label: @toc_label_2).info_item unless @toc_item_2.info_items.map(&:label).include?(@toc_label_2)
    @toc_item_3.info_items << TranslatedInfoItem.gen(label: @toc_label_3).info_item unless @toc_item_3.info_items.map(&:label).include?(@toc_label_3)

    @taxon_concept   = build_taxon_concept(
       comments: [],
       bhl: [],
       sounds: [],
       flash:           [{description: @video_1_text}, {description: @video_2_text}],
       youtube:         [{description: @video_3_text}],
       images:          [{object_cache_url: @image_1}, {object_cache_url: @image_2},
                          {object_cache_url: @image_3}],
       toc:             [{toc_item: @overview, description: @overview_text, license: License.by_nc, rights_holder: "Someone"},
                          {toc_item: @toc_item_2, description: @desc_2, license: License.cc, rights_holder: "Someone"},
                          {toc_item: @toc_item_3, description: @desc_3, license: License.public_domain, rights_holder: ""},
                          {toc_item: @toc_item_3, description: 'test uknown', vetted: Vetted.unknown, license: License.by_nc, rights_holder: "Someone"},
                          {toc_item: @toc_item_3, description: 'test untrusted', vetted: Vetted.untrusted, license: License.cc, rights_holder: "Someone"}])
    @preferred_common_name_synonym = @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, agent: Agent.last, language: Language.english)
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
    @object.toc_items << @toc_item_2
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

    EOL::Data.make_all_nested_sets
    EOL::Data.flatten_hierarchies

    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild

    @default_pages_body = source
  end

  it 'pages should take api key and save it to the log' do
    check_api_key("/api/pages/#{@taxon_concept.id}.json?key=#{@user.api_key}", @user)
  end

  it 'pages should return only published concepts' do
    @taxon_concept.update_column(:published, 0)
    visit("/api/pages/0.4/#{@taxon_concept.id}")
    source.should include('<error>')
    source.should include('</response>')
    @taxon_concept.update_column(:published, 1)
  end

  it 'pages should show one data object per category' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1

    # shouldnt get details without asking for them
    response.xpath('//xmlns:taxon/xmlns:dataObject/xmlns:mimeType').length.should == 0
    response.xpath('//xmlns:taxon/xmlns:dataObject/dc:description').length.should == 0
  end

  it 'pages should be able to limit number of media returned' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=2")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 2
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1

    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?videos=2")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 2
  end

  it 'pages should be able to limit number of text returned' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?text=2")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
  end

  # TODO - these tests are slightly silly because they actually specify the correct number of text items to return...
  # Might be better if it simply checked that the list of data Objects either had the expected subjects or included the expected
  # items. ...But that's a but more work for me that I'm not keen on doing right now.
  it 'pages should be able to take a | delimited list of subjects' do
    label2 = @toc_label_2.gsub(/ /, '%20')
    label3 = @toc_label_3.gsub(/ /, '%20')
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=1&subjects=#{label2}&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1

    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&subjects=#{label3}&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 3

    # %7C == |
    response =
    get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=4&subjects=#{label2}%7C#{label3}&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 4
  end

  it 'pages should be able to return ALL subjects' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?text=5&subjects=all&vetted=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 4
  end

  it 'pages should be able to take a | delimited list of licenses' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=2&licenses=cc-by-nc&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2

    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&licenses=pd&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1

    # %7C == |
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&licenses=cc-by-nc%7Cpd&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 3
  end

  it 'pages should be able to return ALL licenses' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?text=5&licenses=all&subjects=all&vetted=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 4
  end

  it 'pages should be able to get more details on data objects' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?image=1&text=0&details=1")
    # should get 1 image, 1 video and their metadata
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject/xmlns:mimeType').length.should == 2
    response.xpath('//xmlns:taxon/xmlns:dataObject/dc:description').length.should == 2

    images = @taxon_concept.images_from_solr(100)
    # and they should still contain vetted and rating info
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:vettedStatus').
      inner_text.should == images.first.vetted_by_taxon_concept(@taxon_concept).label
      debugger
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:dataRating').
      inner_text.should == images.first.data_rating.to_s
  end

  it 'pages should not filter vetted objects by default' do
    vetted_stasuses = []
    response = get_as_json("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1")
    response['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], order: 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == true
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == true
  end

  it 'pages should filter out all non-trusted objects' do
    vetted_stasuses = []
    response = get_as_json("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=1")
    response['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], order: 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == false
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == false
  end

  it 'pages should filter out untrusted objects' do
    vetted_stasuses = []
    response = get_as_json("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=2")
    response['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], order: 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == true
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == false
  end
  it "pages should filter out trusted and untrusted objects" do
    vetted_stasuses = []
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=3")
    response["dataObjects"].each do |data_object|
      data_object = DataObject.find_by_guid(data_object["identifier"],
                                            order: "id desc")
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    expect(vetted_stasuses.include?(Vetted.unknown.id)).to be_true
    expect(vetted_stasuses.include?(Vetted.trusted.id)).to be_false
    expect(vetted_stasuses.include?(Vetted.untrusted.id)).to be_false
  end
  it "pages should filter out trusted and untrusted objects in xml" do
    response = get_as_xml("/api/pages/1.0/#{@taxon_concept.id}?images=0&text=10&videos=0&details=1&vetted=3")
    response.xpath('//xmlns:taxon/xmlns:dataObject').each do |i|
      response.xpath('//xmlns:taxon/xmlns:dataObject[i]/xmlns:additionalInformation/xmlns:vettedStatus')
      .inner_text.should == "Unreviewed"
    end
  end
  it "pages should filter out trusted and unknown objects" do
    vetted_stasuses = []
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=4")
    response["dataObjects"].each do |data_object|
      data_object = DataObject.find_by_guid(data_object["identifier"],
                                            order: "id desc")
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    expect(vetted_stasuses.include?(Vetted.unknown.id)).to be_false
    expect(vetted_stasuses.include?(Vetted.trusted.id)).to be_false
    expect(vetted_stasuses.include?(Vetted.untrusted.id)).to be_true
  end
  it "pages should filter out trusted and unknown objects in xml" do
    response = get_as_xml("/api/pages/1.0/#{@taxon_concept.id}?images=0&text=10&videos=0&details=1&vetted=4")
    response.xpath('//xmlns:taxon/xmlns:dataObject').each do |i|
      response.xpath('//xmlns:taxon/xmlns:dataObject[i]/xmlns:additionalInformation/xmlns:vettedStatus')
      .inner_text.should == "Untrusted"
    end
  end
  it 'pages should be able to toggle common names' do
    visit("/api/pages/0.4/#{@taxon_concept.id}")
    source.should_not include '<commonName'

    visit("/api/pages/0.4/#{@taxon_concept.id}?common_names=1")
    source.should include '<commonName'
  end

  it 'pages should show which common names are preferred' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?common_names=1")
    @taxon_concept.common_names.each do |name|
      (1..@taxon_concept.common_names.length).each do |index|
        if response.xpath("//xmlns:taxon/xmlns:commonName[#{index}]").inner_text == name.name.string
          value = name.preferred? ? 'true' : ''
          response.xpath("//xmlns:taxon/xmlns:commonName[#{index}]/@eol_preferred").inner_text.should == value
        end
      end
    end
  end

  it 'pages should show data object vetted status and rating by default' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}")
    images = @taxon_concept.images_from_solr(100)
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:vettedStatus').
      inner_text.should == images.first.vetted_by_taxon_concept(@taxon_concept).label
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:dataRating').
      inner_text.should == images.first.data_rating.to_s
  end

  it 'pages should be able to toggle synonyms' do
    taxon = TaxonConcept.gen(published: 1, supercedure_id: 0)
    hierarchy = Hierarchy.gen(label: 'my hierarchy', browsable: 1)
    hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy, taxon_concept: taxon, rank: Rank.gen_if_not_exists(label: 'species'))
    name = Name.gen(string: 'my synonym')
    relation = SynonymRelation.gen_if_not_exists(label: 'not common name')
    synonym = Synonym.gen(hierarchy_entry: hierarchy_entry, name: name, synonym_relation: relation)

    visit("/api/pages/1.0/#{taxon.id}")
    source.should_not include '<synonym'

    visit("/api/pages/1.0/#{taxon.id}?synonyms=1")
    source.should include '<synonym'
  end

  describe "synonyms" do
    before(:all) do
      @taxon = TaxonConcept.gen(published: 1, supercedure_id: 0)
      hierarchy = Hierarchy.gen(label: 'my hierarchy', browsable: 1)
      @resource = Resource.gen(title: "resource_title", hierarchy_id: hierarchy.id)
      hierarchy_entry = HierarchyEntry.gen(hierarchy: hierarchy, taxon_concept: @taxon, rank: Rank.gen_if_not_exists(label: 'species'))
      name = Name.gen(string: 'my synonym 1')
      relation = SynonymRelation.gen_if_not_exists(label: 'not common name')
      synonym = Synonym.gen(hierarchy_entry: hierarchy_entry, name: name, synonym_relation: relation)
    end
    it "displays resource_name in json format" do
      visit("/api/pages/1.0/#{@taxon.id}.json?synonyms=1")
      source.should include "#{@resource.title}"
    end

    it "displays resource_name in xml format" do
      visit("/api/pages/1.0/#{@taxon.id}?synonyms=1")
      source.should include "#{@resource.title}"
    end
  end

  it 'pages should be able to render a JSON response' do
    response = get_as_json("/api/pages/0.4/#{@taxon_concept.id}.json?subjects=all&common_names=1&details=1&text=1&images=1")
    response.class.should == Hash
    response['identifier'].should == @taxon_concept.id
    response['scientificName'].should == @taxon_concept.entry.name.string
    response['dataObjects'].length.should == 3
  end

  it 'pages should return exemplar images first' do
    @taxon_concept.taxon_concept_exemplar_image.should be_nil
    first_image = @taxon_concept.images_from_solr.first
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?details=1&text=0&images=2&videos=0")
    response['dataObjects'].first['identifier'].should == first_image.guid

    all_images = @taxon_concept.images_from_solr
    next_exemplar = all_images.last
    first_image.guid.should_not == next_exemplar.guid
    TaxonConceptExemplarImage.set_exemplar(TaxonConceptExemplarImage.new(taxon_concept: @taxon_concept, data_object: next_exemplar))

    @taxon_concept.reload
    @taxon_concept.taxon_concept_exemplar_image.data_object.guid.should == next_exemplar.guid
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?details=1&text=0&images=2&videos=0")
    response['dataObjects'].first['identifier'].should == next_exemplar.guid
    response['dataObjects'][1]['identifier'].should == first_image.guid
  end

  it 'pages should return exemplar articles first' do
    @taxon_concept.taxon_concept_exemplar_article.should be_nil
    all_texts = @taxon_concept.text_for_user
    first_text = @taxon_concept.overview_text_for_user(nil)
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    response['dataObjects'].first['identifier'].should == first_text.guid

    next_exemplar = all_texts.last
    first_text.guid.should_not == next_exemplar.guid
    TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, next_exemplar.id)

    @taxon_concept.reload
    @taxon_concept.overview_text_for_user(nil).guid.should == next_exemplar.guid
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    response['dataObjects'].first['identifier'].should == next_exemplar.guid
    # This next assertion needn't be true; if, say, the second and third had the same rating (the only other criteria by which
    # they are sorted), then first_text could actually now be third instead of second. I'm skipping this test; don't think it's
    # *especially* important, though ideally we would check that everything is still sorted.
    #
    # response['dataObjects'].second['identifier'].should == first_text.guid
  end

  it 'pages should return preferred common names, no matter their order in the DB' do
    new_synonym = @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, agent: Agent.gen, language: Language.english, preferred: 1)
    last_tcn = TaxonConceptName.last
    last_tcn.name_id = @preferred_common_name_synonym.name_id
    last_tcn.save
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?common_names=1")
    response['vernacularNames'][0]['eol_preferred'].should == true
  end

end
