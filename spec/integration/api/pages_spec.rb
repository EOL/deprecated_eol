# encoding: utf-8
require File.dirname(__FILE__) + '/../../spec_helper'

describe 'API:pages' do
  before(:all) do
    load_foundation_cache
    Capybara.reset_sessions!
    @user = User.gen(:api_key => User.generate_key)

    # DataObjects
    @overview        = TocItem.overview
    @overview_text   = 'This is a test Overview, in all its glory'
    @distribution      = TocItem.gen_if_not_exists(:label => 'Ecology and Distribution')
    @distribution_text = 'This is a test Distribution'
    @description       = TocItem.gen_if_not_exists(:label => 'Description')
    @description_text  = 'This is a test Description, in all its glory'
    @toc_item_2      = TocItem.gen(:view_order => 2)
    @toc_item_3      = TocItem.gen(:view_order => 3)
    @image_1         = FactoryGirl.generate(:image)
    @image_2         = FactoryGirl.generate(:image)
    @image_3         = FactoryGirl.generate(:image)
    @video_1_text    = 'First Test Video'
    @video_2_text    = 'Second Test Video'
    @video_3_text    = 'YouTube Test Video'

    @taxon_concept   = build_taxon_concept(
       :flash           => [{:description => @video_1_text}, {:description => @video_2_text}],
       :youtube         => [{:description => @video_3_text}],
       :images          => [{:object_cache_url => @image_1}, {:object_cache_url => @image_2},
                            {:object_cache_url => @image_3}],
       :toc             => [{:toc_item => @overview, :description => @overview_text, :license => License.by_nc, :rights_holder => "Someone"},
                            {:toc_item => @distribution, :description => @distribution_text, :license => License.cc, :rights_holder => "Someone"},
                            {:toc_item => @description, :description => @description_text, :license => License.public_domain, :rights_holder => ""},
                            {:toc_item => @description, :description => 'test uknown', :vetted => Vetted.unknown, :license => License.by_nc, :rights_holder => "Someone"},
                            {:toc_item => @description, :description => 'test untrusted', :vetted => Vetted.untrusted, :license => License.cc, :rights_holder => "Someone"}])
    @preferred_common_name_synonym = @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, :agent => Agent.last, :language => Language.english)
    @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, :agent => Agent.last, :language => Language.english)

    d = DataObject.last
    d.license = License.by_nc
    d.save!
    @object = DataObject.create(
      :guid                   => '803e5930803396d4f00e9205b6b2bf21',
      :identifier             => 'doid',
      :data_type              => DataType.text,
      :mime_type              => MimeType.gen_if_not_exists(:label => 'text/html'),
      :object_title           => 'default title',
      :language               => Language.find_or_create_by_iso_639_1('en'),
      :license                => License.by_nc,
      :rights_statement       => 'default rights © statement',
      :rights_holder          => 'default rights holder',
      :bibliographic_citation => 'default citation',
      :source_url             => 'http://example.com/12345',
      :description            => 'default description <a href="http://www.eol.org">with some html</a>',
      :object_url             => '',
      :thumbnail_url          => '',
      :location               => 'default location',
      :latitude               => 1.234,
      :longitude              => 12.34,
      :altitude               => 123.4,
      :published              => 1,
      :curated                => 0)
    @object.info_items << InfoItem.gen_if_not_exists(:label => 'Distribution')
    @object.save!

    AgentsDataObject.create(:data_object_id => @object.id,
                            :agent_id => Agent.gen(:full_name => 'agent one', :homepage => 'http://homepage.com/?agent=one&profile=1').id,
                            :agent_role => AgentRole.gen_if_not_exists(:label => 'writer'),
                            :view_order => 1)
    AgentsDataObject.create(:data_object_id => @object.id,
                            :agent => Agent.gen(:full_name => 'agent two'),
                            :agent_role => AgentRole.gen_if_not_exists(:label => 'editor'),
                            :view_order => 2)
    @object.refs << Ref.gen(:full_reference => 'first reference')
    @object.refs << Ref.gen(:full_reference => 'second reference')
    @taxon_concept.add_data_object(@object)

    make_all_nested_sets
    flatten_hierarchies

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
    debugger unless response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
  end

  it 'pages should be able to take a | delimited list of subjects' do
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=1&subjects=GeneralDescription&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1

    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&subjects=Distribution&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2

    # %7C == |
    response = get_as_xml("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&subjects=GeneralDescription%7CDistribution&details=1")
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 3
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
    response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:dataRating').
      inner_text.should == images.first.data_rating.to_s
  end

  it 'pages should not filter vetted objects by default' do
    vetted_stasuses = []
    response = get_as_json("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1")
    response['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
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
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
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
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == true
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == false
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
    taxon = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
    hierarchy = Hierarchy.gen(:label => 'my hierarchy', :browsable => 1)
    hierarchy_entry = HierarchyEntry.gen(:hierarchy => hierarchy, :taxon_concept => taxon, :rank => Rank.gen_if_not_exists(:label => 'species'))
    name = Name.gen(:string => 'my synonym')
    relation = SynonymRelation.gen_if_not_exists(:label => 'not common name')
    synonym = Synonym.gen(:hierarchy_entry => hierarchy_entry, :name => name, :synonym_relation => relation)

    visit("/api/pages/1.0/#{taxon.id}")
    source.should_not include '<synonym'

    visit("/api/pages/1.0/#{taxon.id}?synonyms=1")
    source.should include '<synonym'
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
    first_text = all_texts.first
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    response['dataObjects'].first['identifier'].should == first_text.guid

    next_exemplar = all_texts.last
    first_text.guid.should_not == next_exemplar.guid
    TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, next_exemplar.id)

    @taxon_concept.reload
    @taxon_concept.taxon_concept_exemplar_article.data_object.guid.should == next_exemplar.guid
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    # NOTE - the problem here, and I screwed up while I had it, so will have to fix it later, was that the next_exemplar
    # picked above was UNKNOWN vetted, and thus sorted lower. I don't know if that's desired... if not, then yay! The failing
    # test really indicates a problem. If not, then we need to find a clever way of curating the text object for this test
    # such that it's NOT unknown. I was going to just call DataObjectsHierarchyEntry.where(hierarchy_entry_id:
    # @taxon_concept.entry.id) and loop over those to either set them all to trusted or to find the next_exemplar ... blah
    # blah blah, it's late and I'm losing interest.
    #
    # I suppose it would be easier if the next_exemplar picker above didn't just take the last text, but the last TRUSTED
    # text. ...But perhaps this failure really does indicate a problem.  I don't know.
    debugger unless response['dataObjects'].first['identifier'] == next_exemplar.guid
    response['dataObjects'].first['identifier'].should == next_exemplar.guid
    response['dataObjects'][1]['identifier'].should == first_text.guid
  end

  it 'pages should return preferred common names, no matter their order in the DB' do
    new_synonym = @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, :agent => Agent.gen, :language => Language.english, :preferred => 1)
    last_tcn = TaxonConceptName.last
    last_tcn.name_id = @preferred_common_name_synonym.name_id
    last_tcn.save
    response = get_as_json("/api/pages/1.0/#{@taxon_concept.id}.json?common_names=1")
    response['vernacularNames'][0]['eol_preferred'].should == true
  end

end
