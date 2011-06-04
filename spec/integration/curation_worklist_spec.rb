require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
 curator = build_curator(tc)
 tc.images.last.curator_activity_flag curator, tc.id
 return curator
end

describe 'Curator Worklist' do

  before(:all) do
    commit_transactions
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!

    @taxon_concept = build_taxon_concept()
    @curator = create_curator_for_taxon_concept(@taxon_concept)
    @supplier_user = User.gen()
    @content_partner = ContentPartner.gen(:user => @supplier_user, :description => 'For testing curator worklist')
    @resource = Resource.gen(:content_partner => @content_partner)
    @testing_harvest_event = HarvestEvent.gen(:resource => @resource)

    @ancestor_entry = @taxon_concept.hierarchy_entries[0]
    @child_entry = HierarchyEntry.gen(:parent_id => @ancestor_entry.id, :hierarchy_id => @ancestor_entry.hierarchy_id)
    @child_concept = build_taxon_concept(:id => @child_entry.taxon_concept_id,
                        :images => [{:id => '11111', :vetted => Vetted.unknown},
                                    {:id => '11112', :vetted => Vetted.untrusted},
                                    {:id => '11113', :vetted => Vetted.trusted},
                                    {:id => '11114', :vetted => Vetted.unknown},
                                    {:id => '11115', :vetted => Vetted.untrusted},
                                    {:id => '11116', :vetted => Vetted.trusted}])
    @lower_child_entry = HierarchyEntry.gen(:parent_id => @child_entry.id, :hierarchy_id => @ancestor_entry.hierarchy_id)
    @lower_child_concept = build_taxon_concept(:id => @lower_child_entry.taxon_concept_id,
                        :images => [{:id => '21111', :vetted => Vetted.unknown, :event => @testing_harvest_event},
                                    {:id => '21112', :vetted => Vetted.untrusted, :event => @testing_harvest_event},
                                    {:id => '21113', :vetted => Vetted.trusted, :event => @testing_harvest_event},
                                    {:id => '21114', :vetted => Vetted.unknown, :event => @testing_harvest_event},
                                    {:id => '21115', :vetted => Vetted.untrusted, :event => @testing_harvest_event},
                                    {:id => '21116', :vetted => Vetted.trusted, :event => @testing_harvest_event}])

    # Agent, Content Partner and Hierarchy entry with no image content associated with them.
    @supplier_user_no_content = User.gen()
    @content_partner_no_content = ContentPartner.gen(:user => @supplier_user_no_content, :description => 'For testing curator worklist')
    @child_entry_no_content = HierarchyEntry.gen(:parent_id => @child_entry.id, :hierarchy_id => @ancestor_entry.hierarchy_id)
    @species_name = Name.find_by_id(HierarchyEntry.find_by_id(@child_entry_no_content.id, :select => 'name_id').name_id)

    @first_child_unreviewed_image = DataObject.find('11111')
    @first_child_untrusted_image = DataObject.find('11112')
    @first_child_trusted_image = DataObject.find('11113')

    # @first_child_unreviewed_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('11114'))
    # @first_child_untrusted_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('11115'))
    # @first_child_trusted_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('11116'))

    @lower_child_unreviewed_image = DataObject.find('21111')
    @lower_child_untrusted_image = DataObject.find('21112')
    @lower_child_trusted_image = DataObject.find('21113')

    # @lower_child_unreviewed_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('21114'))
    # @lower_child_untrusted_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('21115'))
    # @lower_child_trusted_ignored_image = UserIgnoredDataObject.create(:user => @curator, :data_object => DataObject.find('21116'))

    make_all_nested_sets
    flatten_hierarchies

    @solr = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
    @solr.delete_all_documents
    @solr.build_data_object_index
  end

  before(:each) do
    SpeciesSchemaModel.connection.execute('set AUTOCOMMIT=1')
    login_as(@curator)
  end

  after(:each) do
    visit('/logout')
    Capybara.reset_sessions!
  end

  after(:all) do
    truncate_all_tables
  end

  it 'should show a list of unreviewed images in the curator\'s clade when curator visits the worklist' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@taxon_concept.hierarchy_entries.first.id}")
    body.should include('Curator Central')
    body.should include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by hierarchy entry id' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}")
    body.should include('Curator Central')
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by content partner' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@taxon_concept.hierarchy_entries.first.id}&content_partner_id=#{@content_partner.id}")
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by vetted status' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@taxon_concept.hierarchy_entries.first.id}&vetted_id=#{Vetted.unknown.id}")
    body.should include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    visit("/curators/curate_images?vetted_id=#{Vetted.untrusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should include(curate_data_object_path @first_child_untrusted_image)
    body.should include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    visit("/curators/curate_images?vetted_id=#{Vetted.trusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should include(curate_data_object_path @lower_child_trusted_image)
    body.should include(curate_data_object_path @first_child_trusted_image)
  end

  it 'should be able to filter images by hierarchy entry id and content partner' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by hierarchy entry id and vetted status' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&vetted_id=#{Vetted.unknown.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&vetted_id=#{Vetted.untrusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&vetted_id=#{Vetted.trusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by content partner and vetted status' do
    visit("/curators/curate_images?content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.unknown.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.untrusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.trusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should include(curate_data_object_path @lower_child_trusted_image)
  end

  it 'should be able to filter images by hierarchy entry id, content partner and vetted status' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.unknown.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.untrusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.trusted.id}")
    body.should_not include(curate_data_object_path @first_child_unreviewed_image)
    body.should_not include(curate_data_object_path @lower_child_unreviewed_image)
    body.should_not include(curate_data_object_path @first_child_untrusted_image)
    body.should_not include(curate_data_object_path @lower_child_untrusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should include(curate_data_object_path @lower_child_trusted_image)
  end

  # it 'should be able to show ignored images regardless of vetted status' do
  #   visit("/curators/ignored_images")
  #   body.should include('Curator Central: Ignored Images')
  #   body.should include(@first_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should include(@first_child_untrusted_ignored_image.data_object_id.to_s)
  #   body.should include(@first_child_trusted_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_untrusted_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_trusted_ignored_image.data_object_id.to_s)
  # end
  #
  it 'should be able to maintain the curator\'s session' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@taxon_concept.hierarchy_entries.first.id}&vetted_id=#{Vetted.trusted.id}")
    body.should include(curate_data_object_path @lower_child_trusted_image)
    body.should include(curate_data_object_path @first_child_trusted_image)
    body.should_not include("There is no Trusted content for #{@species_name}, please select another group to curate or change your source or vetting status criteria.")
    visit("/curators/curate_images?hierarchy_entry_id=#{@child_entry_no_content.id}")
    body.should include("There is no  content for #{@species_name}, please select another group to curate or change your source or vetting status criteria.")
    visit("/curators/curate_images?vetted_id=#{Vetted.trusted.id}")
    body.should_not include(curate_data_object_path @lower_child_trusted_image)
    body.should_not include(curate_data_object_path @first_child_trusted_image)
    body.should include("There is no Trusted content for #{@species_name}, please select another group to curate or change your source or vetting status criteria.")
  #   visit("/curators/curate_images")
  #   body.should include(@first_child_unreviewed_image.id.to_s)
  #   body.should include(@lower_child_unreviewed_image.id.to_s)
  #   visit("/curators/ignored_images")
  #   body.should include(@first_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_unreviewed_ignored_image.data_object_id.to_s)
  #   visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}")
  #   body.should_not include(@first_child_unreviewed_image.id.to_s)
  #   body.should include(@lower_child_unreviewed_image.id.to_s)
  #   visit("/curators/ignored_images?hierarchy_entry_id=#{@lower_child_entry.id}")
  #   body.should_not include(@first_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should_not include(@first_child_untrusted_ignored_image.data_object_id.to_s)
  #   body.should_not include(@first_child_trusted_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_untrusted_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_trusted_ignored_image.data_object_id.to_s)
  #   visit("/curators/curate_images")
  #   body.should_not include(@first_child_unreviewed_image.id.to_s)
  #   body.should include(@lower_child_unreviewed_image.id.to_s)
  #   visit("/curators/ignored_images")
  #   body.should_not include(@first_child_unreviewed_ignored_image.data_object_id.to_s)
  #   body.should include(@lower_child_unreviewed_ignored_image.data_object_id.to_s)
  end

  it 'should be able to give curators feedback about the sorting rationale' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.unknown.id}")
    body.should include("Images are sorted by EOL import date, with newest items shown first.")
    # visit("/curators/ignored_images?hierarchy_entry_id=#{@lower_child_entry.id}&content_partner_id=#{@content_partner.id}&vetted_id=#{Vetted.unknown.id}")
    # body.should include("Images are sorted by EOL import date, with newest items shown first.")
  end

  it 'should be able to give curators a warning message if content is not found' do
    visit("/curators/curate_images?content_partner_id=#{@content_partner_no_content.id}")
    body.should include("There is no  #{@content_partner_no_content.user.full_name} content, please select another group to curate or change your source or vetting status criteria.")
    visit("/curators/curate_images?content_partner_id=#{@content_partner_no_content.id}&vetted_id=#{Vetted.trusted.id}")
    body.should include("There is no Trusted #{@content_partner_no_content.user.full_name} content, please select another group to curate or change your source or vetting status criteria.")
    visit("/curators/curate_images?hierarchy_entry_id=#{@child_entry_no_content.id}&vetted_id=#{Vetted.untrusted.id}")
    body.should include("There is no Untrusted content for #{@species_name}, please select another group to curate or change your source or vetting status criteria.")
    visit("/curators/curate_images?content_partner_id=#{@content_partner_no_content.id}&hierarchy_entry_id=#{@child_entry_no_content.id}&vetted_id=#{Vetted.unknown.id}")
    body.should include("There is no Unreviewed #{@content_partner_no_content.user.full_name} content for #{@species_name}, please select another group to curate or change your source or vetting status criteria.")
    # visit("/curators/ignored_images?hierarchy_entry_id=#{@child_entry_no_content.id}")
    # body.should include("There is no ignored content for #{@species_name}, please select another group.")
  end

  it 'should be able to render the taxon name links to the species page with the same image' do
    visit("/curators/curate_images?hierarchy_entry_id=#{@taxon_concept.hierarchy_entries.first.id}")
    body.should include("/pages/#{@child_entry.taxon_concept_id}")
    body.should include("/curators/curate_image?data_object_id=#{@first_child_unreviewed_image.id.to_s}")
    visit("/curators/curate_image?data_object_id=#{@first_child_unreviewed_image.id.to_s}")
    body.should include("/pages/#{@child_entry.taxon_concept_id}")
  end

  it "should be able to rate the images" do
    visit("/curators/curate_images")
    body.should have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n0")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n1")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n2")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n3")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n4")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n5")
    visit("/data_objects/rate/#{@lower_child_unreviewed_image.id.to_s}?stars=3")
    visit("/curators/curate_images")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n0")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n1")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n2")
    body.should have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n3")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n4")
    body.should_not have_tag("li#user-rating-#{@lower_child_unreviewed_image.id.to_s}.current-rating", :text =>"Your Rating:\n5")
  end

  # it "should be able to rate the ignored images" do
  #   visit("/curators/ignored_images")
  #   body.should have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n0")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n1")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n2")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n3")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n4")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n5")
  #   visit("/data_objects/rate/#{@first_child_unreviewed_ignored_image.data_object_id.to_s}?stars=3")
  #   visit("/curators/ignored_images")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n0")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n1")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n2")
  #   body.should have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n3")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n4")
  #   body.should_not have_tag("li#user-rating-#{@first_child_unreviewed_ignored_image.data_object_id.to_s}.current-rating", :text =>"Your Rating:\n5")
  # end

end
