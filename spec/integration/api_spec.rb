# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

require 'solr_api'

def check_api_key(url, user)
  visit(url)
  log = ApiLog.last
  url.split(/[\?&]/).each do |url_part|
    log.request_uri.should match(url_part)
  end
  log.key.should_not be_nil
  log.key.should == user.api_key
  log.user_id.should == user.id
end

describe 'EOL APIs' do
  before(:all) do
    truncate_all_tables
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
    @taxon_concept.add_common_name_synonym(Faker::Eol.common_name.firstcap, :agent => Agent.last, :language => Language.english)
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

    @text = @taxon_concept.data_objects.delete_if{|d| d.data_type_id != DataType.text.id}
    @images = @taxon_concept.data_objects.delete_if{|d| d.data_type_id != DataType.image.id}


    # HierarchyEntries
    @canonical_form = CanonicalForm.create(:string => 'Aus bus')
    @name = Name.create(:canonical_form => @canonical_form, :string => 'Aus bus Linnaeus 1776')
    @hierarchy = Hierarchy.gen(:label => 'Test Hierarchy', :browsable => 1)
    @rank = Rank.gen_if_not_exists(:label => 'species')
    @hierarchy_entry = HierarchyEntry.gen(:identifier => '123abc', :hierarchy => @hierarchy, :name => @name, :published => 1, :rank => @rank)

    name = Name.create(:string => 'Some critter')
    relation = SynonymRelation.gen_if_not_exists(:label => 'common name')
    language = Language.gen_if_not_exists(:label => 'english', :iso_639_1 => 'en')
    @common_name1 = Synonym.gen(:hierarchy_entry => @hierarchy_entry, :name => name, :synonym_relation => relation, :language => language)
    name = Name.create(:string => 'Some jabberwocky')
    @common_name2 = Synonym.gen(:hierarchy_entry => @hierarchy_entry, :name => name, :synonym_relation => relation, :language => language)


    canonical_form = CanonicalForm.create(:string => 'Dus bus')
    name = Name.create(:canonical_form => @canonical_form, :string => 'Dus bus Linnaeus 1776')
    relation = SynonymRelation.gen_if_not_exists(:label => 'not common name')
    @synonym = Synonym.gen(:hierarchy_entry => @hierarchy_entry, :name => name, :synonym_relation => relation)


    # Search
    @dog_name      = 'Dog'
    @domestic_name = "Domestic #{@dog_name}"
    @dog_sci_name  = 'Canis lupus familiaris'
    @wolf_name     = 'Wolf'
    @wolf_sci_name = 'Canis lupus'
    @wolf = build_taxon_concept(:scientific_name => @wolf_sci_name, :common_names => [@wolf_name])
    @dog  = build_taxon_concept(:scientific_name => @dog_sci_name, :common_names => [@domestic_name], :parent_hierarchy_entry_id => @wolf.hierarchy_entries.first.id)
    @dog2  = build_taxon_concept(:scientific_name => "Canis dog", :common_names => "doggy")

    SearchSuggestion.gen(:taxon_id => @dog.id, :term => @dog_name)
    SearchSuggestion.gen(:taxon_id => @wolf.id, :term => @dog_name)

    # Provider Hierarchies
    @test_hierarchy = Hierarchy.gen(:label => 'Some test hierarchy', :browsable => 1)
    @second_test_hierarchy = Hierarchy.gen(:label => 'Another test hierarchy', :browsable => 1)
    @test_hierarchy_entry_published = HierarchyEntry.gen(:hierarchy => @test_hierarchy, :identifier => 'Animalia', :parent_id => 0, :published => 1, :visibility_id => Visibility.visible.id, :rank => Rank.kingdom)
    @test_hierarchy_entry_unpublished = HierarchyEntry.gen(:hierarchy => @test_hierarchy, :identifier => 'Plantae', :parent_id => 0, :published => 0, :visibility_id => Visibility.invisible.id, :rank => Rank.kingdom)
    @second_test_hierarchy_entry = HierarchyEntry.gen(:hierarchy => @second_test_hierarchy, :identifier => 54321, :parent_id => 0, :published => 1, :visibility_id => Visibility.visible.id, :rank => Rank.kingdom)
    make_all_nested_sets
    flatten_hierarchies
    
    EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
    EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    
    visit("/api/pages/0.4/#{@taxon_concept.id}")
    @default_pages_body = body
  end

  it 'ping should show success message' do
    visit("/api/ping")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//response/message').inner_text.should == 'Success'
  end
  
  it 'should take api key and save it to the log' do
    check_api_key("/api/ping?key=#{@user.api_key}", @user)
  end
  
  it 'pages should return only published concepts' do
    @taxon_concept.update_column(:published, 0)
    visit("/api/pages/0.4/#{@taxon_concept.id}")
    body.should include('<error>')
    body.should include('</response>')
    @taxon_concept.update_column(:published, 1)
  end
  
  it 'pages should show one data object per category' do
    xml_response = Nokogiri.XML(@default_pages_body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
  
    # shouldnt get details without asking for them
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject/xmlns:mimeType').length.should == 0
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject/dc:description').length.should == 0
  end
  
  it 'pages should be able to limit number of media returned' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=2")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 2
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
  
    visit("/api/pages/0.4/#{@taxon_concept.id}?videos=2")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 2
  end
  
  it 'pages should be able to limit number of text returned' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?text=2")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
  end
  
  it 'pages should be able to take a | delimited list of subjects' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=1&subjects=GeneralDescription&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
  
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&subjects=Distribution&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2
  
    # %7C == |
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&subjects=GeneralDescription%7CDistribution&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 3
  end
  
  it 'pages should be able to return ALL subjects' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?text=5&subjects=all&vetted=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 4
  end
  
  it 'pages should be able to take a | delimited list of licenses' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=2&licenses=cc-by-nc&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 2
  
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&licenses=pd&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 1
  
    # %7C == |
    visit("/api/pages/0.4/#{@taxon_concept.id}?images=0&text=3&licenses=cc-by-nc%7Cpd&details=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 3
  end
  
  it 'pages should be able to return ALL licenses' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?text=5&licenses=all&subjects=all&vetted=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/Text"]').length.should == 4
  end
  
  it 'pages should be able to get more details on data objects' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?image=1&text=0&details=1")
    xml_response = Nokogiri.XML(body)
    # should get 1 image, 1 video and their metadata
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/MovingImage"]').length.should == 1
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject/xmlns:mimeType').length.should == 2
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject/dc:description').length.should == 2
  
    images = @taxon_concept.images_from_solr(100)
    # and they should still contain vetted and rating info
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:vettedStatus').
      inner_text.should == images.first.vetted_by_taxon_concept(@taxon_concept, :find_best => true).label
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:dataRating').
      inner_text.should == images.first.data_rating.to_s
  end
  
  it 'pages should not filter vetted objects by default' do
    vetted_stasuses = []
    visit("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1")
    response_object = JSON.parse(body)
    response_object['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept, :find_best => true).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == true
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == true
  end
  
  it 'pages should filter out all non-trusted objects' do
    vetted_stasuses = []
    visit("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=1")
    response_object = JSON.parse(body)
    response_object['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept, :find_best => true).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == false
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == false
  end
  
  it 'pages should filter out untrusted objects' do
    vetted_stasuses = []
    visit("/api/pages/0.4/#{@taxon_concept.id}.json?images=0&text=10&videos=0&details=1&vetted=2")
    response_object = JSON.parse(body)
    response_object['dataObjects'].each do |data_object|
      data_object = DataObject.find_by_guid(data_object['identifier'], :order => 'id desc')
      vetted_stasuses << data_object.vetted_by_taxon_concept(@taxon_concept, :find_best => true).id
    end
    vetted_stasuses.uniq!
    vetted_stasuses.include?(Vetted.unknown.id).should == true
    vetted_stasuses.include?(Vetted.trusted.id).should == true
    vetted_stasuses.include?(Vetted.untrusted.id).should == false
  end
  
  it 'pages should be able to toggle common names' do
    @default_pages_body.should_not include '<commonName'
  
    visit("/api/pages/0.4/#{@taxon_concept.id}?common_names=1")
    body.should include '<commonName'
  end
  
  it 'pages should show which common names are preferred' do
    visit("/api/pages/0.4/#{@taxon_concept.id}?common_names=1")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:taxon/xmlns:commonName[1]/@eol_preferred').inner_text.should == 'true'
    xml_response.xpath('//xmlns:taxon/xmlns:commonName[2]/@eol_preferred').inner_text.should == ''
  end
  
  it 'pages should show data object vetted status and rating by default' do
    xml_response = Nokogiri.XML(@default_pages_body)
    images = @taxon_concept.images_from_solr(100)
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:vettedStatus').
      inner_text.should == images.first.vetted_by_taxon_concept(@taxon_concept, :find_best => true).label
    xml_response.xpath('//xmlns:taxon/xmlns:dataObject[xmlns:dataType="http://purl.org/dc/dcmitype/StillImage"][last()]/xmlns:additionalInformation/xmlns:dataRating').
      inner_text.should == images.first.data_rating.to_s
  end
  
  it 'pages should be able to toggle synonyms' do
    taxon = TaxonConcept.gen(:published => 1, :supercedure_id => 0)
    hierarchy = Hierarchy.gen(:label => 'my hierarchy', :browsable => 1)
    hierarchy_entry = HierarchyEntry.gen(:hierarchy => hierarchy, :taxon_concept => taxon, :rank => @rank)
    name = Name.gen(:string => 'my synonym')
    relation = SynonymRelation.gen_if_not_exists(:label => 'not common name')
    synonym = Synonym.gen(:hierarchy_entry => hierarchy_entry, :name => name, :synonym_relation => relation)
  
    visit("/api/pages/1.0/#{taxon.id}")
    body.should_not include '<synonym'
  
    visit("/api/pages/1.0/#{taxon.id}?synonyms=1")
    body.should include '<synonym'
  end
  
  it 'pages should be able to render a JSON response' do
    visit("/api/pages/0.4/#{@taxon_concept.id}.json?subjects=all&common_names=1&details=1&text=1&images=1")
    response_object = JSON.parse(body)
    response_object.class.should == Hash
    response_object['identifier'].should == @taxon_concept.id
    response_object['scientificName'].should == @taxon_concept.entry.name.string
    response_object['dataObjects'].length.should == 3
  end
  
  it 'pages should take api key and save it to the log' do
    check_api_key("/api/pages/#{@taxon_concept.id}.json?key=#{@user.api_key}", @user)
  end
  
  it 'pages should return exemplar images first' do
    @taxon_concept.taxon_concept_exemplar_image.should be_nil
    first_image = @taxon_concept.images_from_solr.first
    visit("/api/pages/1.0/#{@taxon_concept.id}.json?details=1&text=0&images=2&videos=0")
    response_object = JSON.parse(body)
    response_object['dataObjects'].first['identifier'].should == first_image.guid
    
    all_images = @taxon_concept.images_from_solr
    next_exemplar = all_images.last
    first_image.guid.should_not == next_exemplar.guid
    TaxonConceptExemplarImage.set_exemplar(@taxon_concept, next_exemplar.id)
    
    @taxon_concept = TaxonConcept.find(@taxon_concept.id)
    @taxon_concept.taxon_concept_exemplar_image.data_object.guid.should == next_exemplar.guid
    visit("/api/pages/1.0/#{@taxon_concept.id}.json?details=1&text=0&images=2&videos=0")
    response_object = JSON.parse(body)
    response_object['dataObjects'].first['identifier'].should == next_exemplar.guid
    response_object['dataObjects'][1]['identifier'].should == first_image.guid
  end
  
  it 'pages should return exemplar articles first' do
    @taxon_concept.taxon_concept_exemplar_article.should be_nil
    all_texts = @taxon_concept.text_for_user
    first_text = all_texts.first
    visit("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    response_object = JSON.parse(body)
    response_object['dataObjects'].first['identifier'].should == first_text.guid
    
    next_exemplar = all_texts.last
    first_text.guid.should_not == next_exemplar.guid
    TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, next_exemplar.id)
    
    @taxon_concept = TaxonConcept.find(@taxon_concept.id)
    @taxon_concept.taxon_concept_exemplar_article.data_object.guid.should == next_exemplar.guid
    visit("/api/pages/1.0/#{@taxon_concept.id}.json?subjects=all&details=1&text=5&images=0&videos=0")
    response_object = JSON.parse(body)
    response_object['dataObjects'].first['identifier'].should == next_exemplar.guid
    response_object['dataObjects'][1]['identifier'].should == first_text.guid
  end
  
  # DataObjects
  
  it "data objects should show unpublished objects" do
    @object.update_column(:published, 0)
    visit("/api/data_objects/#{@object.guid}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('/').inner_html.should_not == ""
    xml_response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == @object.guid
    @object.update_column(:published, 1)
  end
  
  it "data objects should show a taxon element for the data object request" do
    visit("/api/data_objects/#{@object.guid}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('/').inner_html.should_not == ""
  
    xml_response.xpath('//xmlns:taxon/dc:identifier').inner_text.should == @object.get_taxon_concepts(:published => :strict)[0].id.to_s
  end
  
  it "data objects should show all information for text objects" do
    # this should be defined in the foundation and linked to its TOC
    DataObjectsTableOfContent.delete_all(:data_object_id => @object.id)
    DataObjectsInfoItem.delete_all(:data_object_id => @object.id)
    @info_item = InfoItem.find_or_create_by_schema_value('http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription');
    DataObjectsTableOfContent.create(:data_object_id => @object.id, :toc_id => @info_item.toc_id)
    DataObjectsInfoItem.create(:data_object_id => @object.id, :info_item => @info_item)
    @object.reload
  
    visit("/api/data_objects/#{@object.guid}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('/').inner_html.should_not == ""
    xml_response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == @object.guid
    xml_response.xpath('//xmlns:dataObject/xmlns:dataType').inner_text.should == @object.data_type.schema_value
    xml_response.xpath('//xmlns:dataObject/xmlns:mimeType').inner_text.should == @object.mime_type.label
    xml_response.xpath('//xmlns:dataObject/dc:title').inner_text.should == @object.object_title
    xml_response.xpath('//xmlns:dataObject/dc:language').inner_text.should == @object.language.iso_639_1
    xml_response.xpath('//xmlns:dataObject/xmlns:license').inner_text.should == @object.license.source_url
    xml_response.xpath('//xmlns:dataObject/dc:rights').inner_text.should == @object.rights_statement
    xml_response.xpath('//xmlns:dataObject/dcterms:rightsHolder').inner_text.should == @object.rights_holder
    xml_response.xpath('//xmlns:dataObject/dcterms:bibliographicCitation').inner_text.should == @object.bibliographic_citation
    xml_response.xpath('//xmlns:dataObject/dc:source').inner_text.should == @object.source_url
    xml_response.xpath('//xmlns:dataObject/xmlns:subject').inner_text.should == @object.info_items[0].schema_value
    xml_response.xpath('//xmlns:dataObject/dc:description').inner_text.should == @object.description
    xml_response.xpath('//xmlns:dataObject/xmlns:location').inner_text.should == @object.location
    xml_response.xpath('//xmlns:dataObject/geo:Point/geo:lat').inner_text.should == @object.latitude.to_s
    xml_response.xpath('//xmlns:dataObject/geo:Point/geo:long').inner_text.should == @object.longitude.to_s
    xml_response.xpath('//xmlns:dataObject/geo:Point/geo:alt').inner_text.should == @object.altitude.to_s
  
    # testing agents
    xml_response.xpath('//xmlns:dataObject/xmlns:agent').length.should == 2
    xml_response.xpath('//xmlns:dataObject/xmlns:agent[1]').inner_text.should == @object.agents[0].full_name
    xml_response.xpath('//xmlns:dataObject/xmlns:agent[1]/@homepage').inner_text.should == @object.agents[0].homepage
    xml_response.xpath('//xmlns:dataObject/xmlns:agent[1]/@role').inner_text.should == @object.agents_data_objects[0].agent_role.label.downcase
    xml_response.xpath('//xmlns:dataObject/xmlns:agent[2]').inner_text.should == @object.agents[1].full_name
    xml_response.xpath('//xmlns:dataObject/xmlns:agent[2]/@role').inner_text.should == @object.agents_data_objects[1].agent_role.label.downcase
  
    #testing references
    xml_response.xpath('//xmlns:dataObject/xmlns:reference').length.should == 2
    xml_response.xpath('//xmlns:dataObject/xmlns:reference[1]').inner_text.should == @object.refs[0].full_reference
    xml_response.xpath('//xmlns:dataObject/xmlns:reference[2]').inner_text.should == @object.refs[1].full_reference
  end
  
  it 'data objects should be able to render a JSON response' do
    # this should be defined in the foundation and linked to its TOC
    DataObjectsTableOfContent.delete_all(:data_object_id => @object.id)
    DataObjectsInfoItem.delete_all(:data_object_id => @object.id)
    @info_item = InfoItem.find_or_create_by_schema_value('http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription');
    DataObjectsTableOfContent.create(:data_object_id => @object.id, :toc_id => @info_item.toc_id)
    DataObjectsInfoItem.create(:data_object_id => @object.id, :info_item => @info_item)
    @object.reload
  
    visit("/api/data_objects/#{@object.guid}.json")
    response_object = JSON.parse(body)
    response_object.class.should == Hash
    response_object['dataObjects'][0]['identifier'].should == @object.guid
    response_object['dataObjects'][0]['dataType'].should == @object.data_type.schema_value
    response_object['dataObjects'][0]['mimeType'].should == @object.mime_type.label
    response_object['dataObjects'][0]['title'].should == @object.object_title
    response_object['dataObjects'][0]['language'].should == @object.language.iso_639_1
    response_object['dataObjects'][0]['license'].should == @object.license.source_url
    response_object['dataObjects'][0]['rights'].should == @object.rights_statement
    response_object['dataObjects'][0]['rightsHolder'].should == @object.rights_holder
    response_object['dataObjects'][0]['bibliographicCitation'].should == @object.bibliographic_citation
    response_object['dataObjects'][0]['source'].should == @object.source_url
    response_object['dataObjects'][0]['subject'].should == @object.info_items[0].schema_value
    response_object['dataObjects'][0]['description'].should == @object.description
    response_object['dataObjects'][0]['location'].should == @object.location
    response_object['dataObjects'][0]['latitude'].should == @object.latitude
    response_object['dataObjects'][0]['longitude'].should == @object.longitude
    response_object['dataObjects'][0]['altitude'].should == @object.altitude
  
    # testing agents
    response_object['dataObjects'][0]['agents'].length.should == 2
  
    #testing references
    response_object['dataObjects'][0]['references'].length.should == 2
  end
  
  it "data objects should show all information for image objects" do
    @object.data_type = DataType.image
    @object.mime_type = MimeType.gen_if_not_exists(:label => 'image/jpeg')
    @object.object_url = 'http://images.marinespecies.org/resized/23745_electra-crustulenta-pallas-1766.jpg'
    @object.object_cache_url = 200911302039366
    @object.save!
  
    visit("/api/data_objects/#{@object.guid}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('/').inner_html.should_not == ""
    xml_response.xpath('//xmlns:dataObject/dc:identifier').inner_text.should == @object.guid
    xml_response.xpath('//xmlns:dataObject/xmlns:dataType').inner_text.should == @object.data_type.schema_value
    xml_response.xpath('//xmlns:dataObject/xmlns:mimeType').inner_text.should == @object.mime_type.label
  
    #testing images
    xml_response.xpath('//xmlns:dataObject/xmlns:mediaURL').length.should == 2
    xml_response.xpath('//xmlns:dataObject/xmlns:mediaURL[1]').inner_text.should == @object.object_url
    xml_response.xpath('//xmlns:dataObject/xmlns:mediaURL[2]').inner_text.gsub(/\//, '').should include(@object.object_cache_url.to_s)
  end
  
  it 'data objects should be able to toggle common names' do
    visit("/api/data_objects/#{@object.guid}")
    body.should_not include '<commonName'
  
    visit("/api/data_objects/#{@object.guid}?common_names=1")
    body.should include '<commonName'
  end
  
  it 'data objects should take api key and save it to the log' do
    check_api_key("/api/data_objects/#{@object.guid}?key=#{@user.api_key}", @user)
  end
  
  it 'hierarchy_entries should return only published hierarchy_entries' do
    @hierarchy_entry.update_column(:published, 0)
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}")
    body.should include('<error>')
    body.should include('</response>')
    @hierarchy_entry.update_column(:published, 1)
  end
  
  it 'hierarchy_entries should show all information for hierarchy entries in DWC format' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dc:identifier").inner_text.should == @hierarchy_entry.identifier
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonID").inner_text.should == @hierarchy_entry.id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:parentNameUsageID").inner_text.should == @hierarchy_entry.parent_id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonConceptID").inner_text.should == @hierarchy_entry.taxon_concept_id.to_s
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:scientificName").inner_text.should == @name.string
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:taxonRank").inner_text.downcase.should == @rank.label
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:nameAccordingTo").inner_text.should == @hierarchy.label
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:vernacularName[1]").inner_text.should == @common_name1.name.string
    xml_response.xpath("//dwc:Taxon[dwc:taxonID=#{@hierarchy_entry.id}]/dwc:vernacularName[1]/@xml:lang").inner_text.should == @common_name1.language.iso_639_1
    xml_response.xpath("//dwc:vernacularName").length.should == 2
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 1
  end
  
  it 'hierarchy_entries should be able to filter out common names' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?common_names=0")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath("//dwc:vernacularName").length.should == 0
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 1
  end
  
  it 'hierarchy_entries should be able to filter out synonyms' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?synonyms=0")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath("//dwc:vernacularName").length.should == 2
    xml_response.xpath("//dwc:Taxon[dwc:taxonomicStatus='not common name']").length.should == 0
  end
  
  it 'hierarchy_entries should show all information for hierarchy entries in TCS format' do
    visit("/api/hierarchy_entries/#{@hierarchy_entry.id}?format=tcs")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@name.id}"
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @name.string
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should == @canonical_form.string
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Rank').inner_text.downcase.should == @rank.label
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Rank/@code').inner_text.should == @rank.tcs_code
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:ProviderSpecificData/xmlns:NameSources/xmlns:NameSource/xmlns:Simple').inner_text.should == @hierarchy.label
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "#{@hierarchy_entry.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@name.string}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "true"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@ref').inner_text.should == "n#{@name.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Rank').inner_text.downcase.should == @rank.label
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Rank/@code').inner_text.should == @rank.tcs_code
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/xmlns:ToTaxonConcept/@ref').inner_text.should include(@synonym.id.to_s)
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[1]/@type').inner_text.should == 'has synonym'
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[2]/xmlns:ToTaxonConcept/@ref').inner_text.should include(@common_name1.id.to_s)
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:TaxonRelationships/xmlns:TaxonRelationship[2]/@type').inner_text.should == 'has vernacular'
  end
  
  it 'hierarchy_entries should take api key and save it to the log' do
    check_api_key("/api/hierarchy_entries/#{@hierarchy_entry.id}?format=tcs&key=#{@user.api_key}", @user)
  end
  
  it 'synonyms should show all information for synonyms in TCS format' do
    visit("/api/synonyms/#{@synonym.id}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@synonym.name.id}"
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @synonym.name.string
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should == @synonym.name.canonical_form.string
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "s#{@synonym.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@synonym.name.string}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "true"
  end
  
  it 'synonyms should show all information for common names in TCS format' do
    visit("/api/synonyms/#{@common_name1.id}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/@id').inner_text.should == "n#{@common_name1.name.id}"
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:Simple').inner_text.should == @common_name1.name.string
    # canonical form not included for common names
    xml_response.xpath('//xmlns:TaxonNames/xmlns:TaxonName/xmlns:CanonicalName/xmlns:Simple').inner_text.should == ""
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/@id').inner_text.should == "s#{@common_name1.id}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name').inner_text.should == "#{@common_name1.name.string}"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@scientific').inner_text.should == "false"
    xml_response.xpath('//xmlns:TaxonConcepts/xmlns:TaxonConcept/xmlns:Name/@language').inner_text.should == @common_name1.language.iso_639_1
  end
  
  it 'synonyms should take api key and save it to the log' do
    check_api_key("/api/synonyms/#{@common_name1.id}?key=#{@user.api_key}", @user)
  end

  it 'search should do a contains search by default' do
    visit("/api/search/Canis%20lupus.json")
    response_object = JSON.parse(body)
    response_object['results'].length.should == 2
  end

  it 'search should do an exact search' do
    visit("/api/search/Canis%20lupus.json?exact=1")
    response_object = JSON.parse(body)
    response_object['results'].length.should == 1
    response_object['results'][0]['title'].should == @wolf_sci_name
  
    visit("/api/search/Canis.json?exact=1")
    response_object = JSON.parse(body)
    response_object['results'].length.should == 0
  end

  it 'search should search without a filter and get multiple results' do
    visit("/api/search/Dog.json")
    response_object = JSON.parse(body)
    response_object['results'][0]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response_object['results'][1]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response_object['results'][2]['title'].should match(/(#{@dog_sci_name}|Canis dog|Canis lupus)/)
    response_object['results'].length.should == 3
  end
  
  it 'search should be able to filter by string' do
    visit("/api/search/Dog.json?filter_by_string=Canis%20lupus")
    response_object = JSON.parse(body)
    response_object['results'][0]['title'].should == @dog_sci_name
    response_object['results'].length.should == 1
  end
  
  it 'search should be able to filter by taxon_concept_id' do
    visit("/api/search/Dog.json?filter_by_taxon_concept_id=#{@wolf.id}")
    response_object = JSON.parse(body)
    response_object['results'][0]['title'].should == @dog_sci_name
    response_object['results'].length.should == 1
  end
  
  it 'search should be able to filter by hierarchy_entry_id' do
    visit("/api/search/Dog.json?filter_by_hierarchy_entry_id=#{@wolf.hierarchy_entries.first.id}")
    response_object = JSON.parse(body)
    response_object['results'][0]['title'].should == @dog_sci_name
    response_object['results'].length.should == 1
  end

  it 'search should take api key and save it to the log' do
    check_api_key("/api/search/Canis.json?exact=1&key=#{@user.api_key}", @user)
  end

  it 'provider_hierarchies should return a list of all providers' do
    visit("/api/provider_hierarchies")
    xml_response = Nokogiri.XML(body)
    our_result = xml_response.xpath("//hierarchy[@id='#{@test_hierarchy.id}']")
    our_result.length.should == 1
    our_result.inner_text.should == @test_hierarchy.label

    visit("/api/provider_hierarchies.json")
    response_object = JSON.parse(body)
    response_object.length.should > 0
    response_object.collect{ |r| r['id'].to_i == @test_hierarchy.id && r['label'] == @test_hierarchy.label }.length == 2
  end

  it 'search_by_provider should return the EOL page ID for a provider identifer' do
    visit("/api/search_by_provider/#{@test_hierarchy_entry_published.identifier}?hierarchy_id=#{@test_hierarchy_entry_published.hierarchy_id}")
    xml_response = Nokogiri.XML(body)
    our_result = xml_response.xpath("//eol_page_id")
    our_result.length.should == 1
    our_result.inner_text.to_i.should == @test_hierarchy_entry_published.taxon_concept_id
    visit("/api/search_by_provider/#{@test_hierarchy_entry_published.identifier}.json?hierarchy_id=#{@test_hierarchy_entry_published.hierarchy_id}")
    response_object = JSON.parse(body)
    response_object.length.should > 0
    response_object.collect{ |r| r['eol_page_id'].to_i == @test_hierarchy_entry_published.taxon_concept_id}.length == 1
  end

  it 'search_by_provider should not return the EOL page ID for a provider identifer' do
    visit("/api/search_by_provider/#{@test_hierarchy_entry_unpublished.identifier}?hierarchy_id=#{@test_hierarchy_entry_unpublished.hierarchy_id}")
    xml_response = Nokogiri.XML(body)
    our_result = xml_response.xpath("//eol_page_id")
    our_result.length.should == 0
    visit("/api/search_by_provider/#{@test_hierarchy_entry_unpublished.identifier}.json?hierarchy_id=#{@test_hierarchy_entry_unpublished.hierarchy_id}")
    response_object = JSON.parse(body)
    response_object.length.should == 0
  end

  it 'search_by_provider should take api key and save it to the log' do
    check_api_key("/api/search_by_provider/#{@test_hierarchy_entry_unpublished.identifier}.json?hierarchy_id=#{@test_hierarchy_entry_unpublished.hierarchy_id}&key=#{@user.api_key}", @user)
  end

  it 'hierarchies should list the hierarchy roots' do
    visit("/api/hierarchies/#{@test_hierarchy.id}")
    xml_response = Nokogiri.XML(body)
    our_result = xml_response.xpath("//dc:title").inner_text.should == @test_hierarchy.label
    our_result = xml_response.xpath("//dc:contributor").inner_text.should == @test_hierarchy.agent.full_name
    our_result = xml_response.xpath("//dc:dateSubmitted").inner_text.should == @test_hierarchy.indexed_on.mysql_timestamp
    our_result = xml_response.xpath("//dc:source").inner_text.should == @test_hierarchy.url
    our_result = xml_response.xpath("//dwc:Taxon").length.should == 1
    our_result = xml_response.xpath("//dwc:Taxon/dwc:taxonID").inner_text.should == @test_hierarchy_entry_published.id.to_s
    our_result = xml_response.xpath("//dwc:Taxon/dwc:parentNameUsageID").inner_text.should == 0.to_s
    our_result = xml_response.xpath("//dwc:Taxon/dwc:taxonConceptID").inner_text.should == @test_hierarchy_entry_published.taxon_concept_id.to_s
    our_result = xml_response.xpath("//dwc:Taxon/dwc:scientificName").inner_text.should == @test_hierarchy_entry_published.name.string
    our_result = xml_response.xpath("//dwc:Taxon/dwc:taxonRank").inner_text.should == @test_hierarchy_entry_published.rank.label

    visit("/api/hierarchies/#{@test_hierarchy.id}.json")
    response_object = JSON.parse(body)
    response_object['title'].should == @test_hierarchy.label
    response_object['contributor'].should == @test_hierarchy.agent.full_name
    response_object['dateSubmitted'].should == @test_hierarchy.indexed_on.mysql_timestamp
    response_object['source'].should == @test_hierarchy.url
    response_object['roots'].length.should == 1
    response_object['roots'][0]['taxonID'].should == @test_hierarchy_entry_published.id
    response_object['roots'][0]['parentNameUsageID'].should == 0
    response_object['roots'][0]['taxonConceptID'].should == @test_hierarchy_entry_published.taxon_concept_id
    response_object['roots'][0]['scientificName'].should == @test_hierarchy_entry_published.name.string
    response_object['roots'][0]['taxonRank'].should == @test_hierarchy_entry_published.rank.label
  end

  it 'hierarchies should take api key and save it to the log' do
    check_api_key("/api/hierarchies/#{@test_hierarchy.id}?key=#{@user.api_key}", @user)
  end

  it 'collections should return XML' do
    c = Collection.gen(:name => "TESTING COLLECTIONS API", :description => "SOME DESCRIPTION")
    visit("/api/collections/#{c.id}")
    xml_response = Nokogiri.XML(body)
    xml_response.xpath("//name").inner_text.should == c.name
    xml_response.xpath("//description").inner_text.should == c.description
  end
  
  it 'collections should return JSON' do
    c = Collection.gen(:name => "TESTING COLLECTIONS API", :description => "SOME DESCRIPTION")
    visit("/api/collections/#{c.id}.json")
    response_object = JSON.parse(body)
    response_object.class.should == Hash
    response_object['name'].should == c.name
    response_object['description'].should == c.description
  end
end

