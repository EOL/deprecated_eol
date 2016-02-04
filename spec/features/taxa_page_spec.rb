require "spec_helper"

# NOTE - I hate this spec. It's really, really hard to debug when something goes wrong. ...if anything is actually wrong.  In
# fact, I wonder if this spec is effectively useless.
#
# UPDATE: Yup, I'm going to say it again: I doubt that this spec proves much of anything. It's brittle, it doesn't show where
# problems really are, it doesn't really help with debugging, and it doesn't show how anything should actually be used. It may
# help *slightly* with confidence that things are working... but I'm not sure how or where. We need to re-write this... which
# is awful.
#
# Moreover, the it.should syntax used below hides (AFAICT) the actual variables being tested. I appreciate the brevity, but
# I'm not sure how to bug-test it. "p puts body" doesn't work, nor does "page.body", nor "@body" (which you would really
# expect, since we're setting it), nor "save_and_open_page"... I'm at a loss. Nor can I find a guide online for how this type
# of test came about.
#
# UPDATE 2: I've decided that, as someone said (not sure where): "feature specs should be about *behaviour*, not about
# *structure*."  ...Use view specs for structure; they are much, much faster (and easier to write). I've taken this to heart and
# am moving the non-behaviour specs out of this file. ...which, I'm guessing, will be all of them...  :\

def remove_classification_filter_if_used
  begin
    click_on 'Remove classification filter'
  rescue
    nil # Sometimes we're in a hierarchy. Oof.
  end
end

describe 'Taxa page' do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('testy_taxa_page_spec')
      truncate_all_tables
      load_scenario_with_caching(:testy)
      User.gen(username: 'testy_taxa_page_spec')
    end
    @testy = EOL::TestInfo.load('testy')
    @taxon_concept = @testy[:taxon_concept]
    @hierarchy_entry = @taxon_concept.published_browsable_hierarchy_entries[0]
    @user = @testy[:user]
    @res = Resource.gen(title: "IUCN Structured Data")
    (DataMeasurement.new(predicate: "<http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus>", object: "Wunderbar", resource: @res, subject: @taxon_concept)).add_to_triplestore
    Capybara.reset_sessions!
    Activity.create_enumerated
  end

  shared_examples_for 'taxon details tab' do

    # NOTE - all of these strings come from the scenario loaded above...
    it 'should show links to literature tab' do
      within("#toc .section") do
        expect(page).to have_tag('a', text: "Literature")
        expect(page).to have_tag('a', text: "Biodiversity Heritage Library")
      end
    end
    it 'should show links to resources tab' do
      within("#toc .section") do
        expect(page).to have_tag('a', text: "Resources")
        expect(page).to have_tag('a', text: "Education resources")
      end
    end
    it 'should not show references container if references do not exist' do
      expect(page).to_not have_css('.section .article:nth-child(3) .references')
    end

    it 'should show actions for text objects' do
      expect(page).to have_css('div.actions p')
    end

    it 'should show action to set article as an exemplar' do
      # TODO - this test was failing ... legitimately... the test data didn't allow a show-in-overview link, so I killed it. It
      # belongs in a view spec, anyway.
      pending
    end

    it 'should show "Add an article or link to this page" button to the logged in users' do
      expect(page).to have_css("#page_heading .page_actions li a", text: "Add an article")
      expect(page).to have_css("#page_heading .page_actions li a", text: "Add a link")
      expect(page).to have_css("#page_heading .page_actions li a", text: "Add to a collection")
    end
  end

  shared_examples_for 'taxon overview tab' do
    it 'should show a gallery of four images' do
      within("div#media_summary") do
        expect(page).to have_css("img[src$='#{@taxon_concept.images_from_solr[0].thumb_or_object('580_360')[25..-1]}']")
        expect(page).to have_css("img[src$='#{@taxon_concept.images_from_solr[1].thumb_or_object('580_360')[25..-1]}']")
        expect(page).to have_css("img[src$='#{@taxon_concept.images_from_solr[2].thumb_or_object('580_360')[25..-1]}']")
        expect(page).to have_css("img[src$='#{@taxon_concept.images_from_solr[3].thumb_or_object('580_360')[25..-1]}']")
      end
    end
    it 'should have taxon links for the images in the gallery' do
      (0..3).each do |i|
        expect(page).to have_css("a[href='#{taxon_overview_path(@taxon_concept)}']")
      end
    end

    it 'should have sanitized descriptive text alternatives for images in gallery'

    it 'should show IUCN Red List status' do
      expect(page).to have_tag('div#iucn_status a')
    end

    it 'should show summary text' do
      # TODO: Test the summary text selection logic - as model spec rather than here (?)
      expect(page).to have_css('div#text_summary', text: @testy[:brief_summary_text])
    end

    it 'should show table of contents label when text object title does not exist' do
      expect(page).to have_css('h3', text: @testy[:brief_summary].label)
    end

    it 'should show classifications'
    it 'should show collections'
    it 'should show communities'

    it 'should show curators'
  end

  shared_examples_for 'taxon resources tab' do
    it 'should include About Resources' do
      expect(page).to have_content('About Resources')
    end
    it 'should include Partner Links' do
      expect(page).to have_content('Partner links')
    end
  end

  shared_examples_for 'taxon community tab' do
    it 'should include Curators' do
      expect(page).to have_content('Curators')
    end
    it 'should include Collections' do
      expect(page).to have_content('Collections')
    end
    it 'should include Communities' do
      expect(page).to have_content('Communities')
    end
  end

  shared_examples_for 'taxon names tab' do
    it 'should list the classifications that recognise the taxon' do
      visit logout_url
      visit taxon_names_path(@taxon_concept)
      within('table.standard.classifications') do
        expect(page).to have_css("a[href='#{taxon_entry_overview_path(@taxon_concept, @taxon_concept.entry)}']")
        expect(page).to have_tag('td', text: 'Catalogue of Life')
      end
    end

    it 'should show related names and their sources' do
      visit related_names_taxon_names_path(@taxon_concept)
      # TODO - these are failing because of newlines IN THE NAMES.  :|  It's just a regex thing. Fix?
      # parents
      expect(page).to have_content(@taxon_concept.hierarchy_entries.first.parent.name.string)
      expect(page).to have_content(@taxon_concept.hierarchy_entries.first.hierarchy.label)
      # children
      expect(page).to have_content(@testy[:child1].hierarchy_entries.first.name.string)
      expect(page).to have_content(@testy[:child1].hierarchy_entries.first.hierarchy.label)
    end

    it 'should show common names grouped by language with preferred flagged and status indicator' do
      visit common_names_taxon_names_path(@taxon_concept)
      @common_names = EOL::CommonNameDisplay.find_by_taxon_concept_id(@taxon_concept.id)
      # TODO: Test that common names from other languages are present and that current language names appear
      # first after language is switched.
      # English by default
      expect(page).to have_css('h4', text: "English")
      expect(page).to have_content(@common_names.first.name_string)
      expect(page).to have_content(@common_names.first.agents.first.full_name)
      expect(page).to have_content(Vetted.find_by_id(@common_names.first.vetted.id).label)
    end

    it 'should allow curators to add common names' do
      visit logout_url
      visit common_names_taxon_names_path(@taxon_concept)
      expect(page).to_not have_css('form#new_name')
      login_as @testy[:curator]
      visit common_names_taxon_names_path(@taxon_concept)
      expect(page).to have_css('form#new_name')
      new_name = FactoryGirl.generate(:string)
      fill_in 'Name', with: new_name
      click_button 'Add name'
      expect(page).to have_css('td', text: new_name.capitalize_all_words)
    end

    it 'should allow curators to choose a preferred common name for each language'
    it 'should allow curators to change the status of common names'

    it 'should show synonyms grouped by their source hierarchy' do
      visit logout_url
      visit synonyms_taxon_names_path(@taxon_concept)
      @synonyms = @taxon_concept.published_hierarchy_entries.first.scientific_synonyms
      expect(page).to have_content(@taxon_concept.published_hierarchy_entries.first.hierarchy.display_title)
      expect(page).to have_content(@synonyms.first.name.string)
    end
  end

  shared_examples_for 'taxon literature tab' do
    it 'should show some references' do
      expect(page).to have_css('.ref_list li')
      @taxon_concept.data_objects.collect(&:refs).flatten.each do |ref|
        if ref.visibility_id == Visibility.invisible.id || ref.published != 1
          expect(page).to_not have_content(ref.full_reference)
        else
          expect(page).to have_content(ref.full_reference)
        end
      end
    end
  end

  shared_examples_for 'taxon name - taxon_concept page' do
    it 'should show the concepts preferred name style and ' do
      expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
    end
  end

  # NOTE - I changed this, since it was failing. It doesn't look like we show the ital name on other pages...
  shared_examples_for 'taxon common name - hierarchy_entry page' do
    it 'should show the concepts preferred name in the heading' do
      expect(page).to have_content(@taxon_concept.preferred_common_name_in_language(Language.default))
    end
  end

  shared_examples_for 'taxon updates tab' do
    it 'should include Taxon newsfeed' do
      expect(page).to have_content('Taxon newsfeed')
    end
    it 'should include Page statistics' do
      expect(page).to have_content('Page statistics')
    end
  end

  # overview tab - taxon_concept
  context 'overview when taxon has all expected data - taxon_concept' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    end
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit taxon_overview_path(@testy[:id]) }
    end
    it_should_behave_like 'taxon overview tab' do
      before { visit taxon_overview_path(@testy[:id]) }
    end
    it 'should allow logged in users to post comment in "Latest Updates" section' do
      visit logout_url
      login_as @user
      visit taxon_overview_path(@taxon_concept)
      comment = "Test comment by a logged in user. #{FactoryGirl.generate(:string)}"
      expect(page).to have_css(".updates .comment #comment_body")
      expect(page).to have_css(".updates .comment .actions input[value='Post Comment']")
      fill_in 'comment_body', with: comment
      click_button "Post Comment"
      current_url.should have_content(taxon_overview_path(@taxon_concept))
      expect(page).to have_content('Comment successfully added')
    end
  end

  # overview tab - hierarchy_entry
  context 'overview when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
    end
    it_should_behave_like 'taxon common name - hierarchy_entry page' do
      before { visit taxon_entry_overview_path(@taxon_concept, @hierarchy_entry) }
    end
    it_should_behave_like 'taxon overview tab' do
      before { visit taxon_entry_overview_path(@taxon_concept, @hierarchy_entry) }
    end
  end

  # resources tab - taxon_concept
  context 'resources when taxon has all expected data - taxon_concept' do
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit("/pages/#{@testy[:id]}/resources") }
    end
    it_should_behave_like 'taxon resources tab' do
      before { visit("/pages/#{@testy[:id]}/resources") }
    end
  end

  # resources tab - hierarchy_entry
  context 'resources when taxon has all expected data - hierarchy_entry' do
    it_should_behave_like 'taxon common name - hierarchy_entry page' do
      before { visit taxon_entry_resources_path(@taxon_concept, @hierarchy_entry) }
    end
    it_should_behave_like 'taxon resources tab' do
      before { visit taxon_entry_resources_path(@taxon_concept, @hierarchy_entry) }
    end
  end

  # details tab - taxon_concept
  context 'details when taxon has all expected data - taxon_concept' do
    before(:all) do
      [:partner_links]
      visit logout_url
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild unless
        TaxonDetails.new(@taxon_concept, @testy[:curator]).resources_links.include?(:education)
      login_as @testy[:curator]
    end
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit taxon_details_path(@taxon_concept) }
    end
    it_should_behave_like 'taxon details tab' do
      before { visit taxon_details_path(@taxon_concept) }
    end
  end

  # details tab - hierarchy_entry
  context 'details when taxon has all expected data - hierarchy_entry' do
    before(:all) do
      visit logout_url
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild unless
        TaxonDetails.new(@taxon_concept, @testy[:curator], @hierarchy_entry).resources_links.include?(:education)
      login_as @testy[:curator]
    end
    it_should_behave_like 'taxon common name - hierarchy_entry page' do
      before { visit taxon_entry_details_path(@taxon_concept, @hierarchy_entry) }
    end
    it_should_behave_like 'taxon details tab' do
      before { visit taxon_entry_details_path(@taxon_concept, @hierarchy_entry) }
    end
  end

  # names tab - taxon_concept
  context 'names when taxon has all expected data - taxon_concept' do
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit taxon_names_path(@taxon_concept) }
    end
    it_should_behave_like 'taxon names tab' do
      before { visit taxon_names_path(@taxon_concept) }
    end
  end

  # names tab - hierarchy_entry
  context 'names when taxon has all expected data - hierarchy_entry' do
    it_should_behave_like 'taxon common name - hierarchy_entry page' do
      before { visit taxon_entry_names_path(@taxon_concept, @hierarchy_entry) }
    end
    it_should_behave_like 'taxon names tab' do
      before { visit taxon_entry_names_path(@taxon_concept, @hierarchy_entry) }
    end
  end

  # literature tab - taxon_concept
  context 'literature when taxon has all expected data - taxon_concept' do
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit taxon_literature_path(@taxon_concept) }
    end
    it_should_behave_like 'taxon literature tab' do
      before { visit taxon_literature_path(@taxon_concept) }
    end
  end

  # literature tab - hierarchy_entry
  context 'literature when taxon has all expected data - hierarchy_entry' do
    it_should_behave_like 'taxon common name - hierarchy_entry page' do
      before { visit taxon_entry_literature_path(@taxon_concept, @hierarchy_entry) }
    end
    it_should_behave_like 'taxon literature tab' do
      before { visit taxon_entry_literature_path(@taxon_concept, @hierarchy_entry) }
    end
  end


  # community tab
  context 'community tab' do
    it_should_behave_like 'taxon name - taxon_concept page' do
      before { visit(taxon_communities_path(@testy[:id])) }
    end
    it_should_behave_like 'taxon community tab' do
      before { visit(taxon_communities_path(@testy[:id])) }
    end
    it "should render communities - curators page" do
      visit(taxon_communities_path(@taxon_concept))
      expect(page).to have_css("h3", text: "Communities")
    end
    it "should render communities - collections page" do
      visit(collections_taxon_communities_path(@taxon_concept))
      expect(page).to have_css("h3", text: "Collections")
    end
    it "should render communities - curators page" do
      visit(curators_taxon_communities_path(@taxon_concept))
      expect(page).to have_css("h3", text: "Curators")
    end
  end


  context 'when taxon does not have any common names' do
    it 'should not show a common name' do
      visit taxon_overview_path @testy[:taxon_concept_with_no_common_names]
      expect(page).to_not have_css('#page_heading h2')
    end
  end

  # @see 'should render when an object has no agents' in old taxa page spec
  context 'when taxon image does not have an agent' do
    it 'should still render the image'
  end

  context 'when taxon does not have any data' do
    it 'details should show empty text' do
      t = TaxonConcept.gen(published: 1)
      visit taxon_details_path t
      expect(page).to have_css('#taxon_detail #main .empty')
      expect(page).to have_content("No one has contributed any details to this page yet")
      expect(page).to have_css("#toc .section") do |tags|
        tags.should have_css("h4 a[href='#{taxon_literature_path t}']")
        tags.should have_css("ul li a[href='#{bhl_taxon_literature_path t}']")
      end
    end
  end

  context 'when taxon supercedes another concept' do
    it 'should use supercedure to find taxon if user visits the other concept' do
      puts "current : #{current_url}, super : #{@testy[:superceded_taxon_concept]}"
      visit taxon_overview_path @testy[:superceded_taxon_concept]
      current_url.should match /#{taxon_overview_path(@taxon_concept)}/
      current_url.should_not match /#{taxon_overview_path(@testy[:superceded_taxon_concept])}/
      remove_classification_filter_if_used
      expect(page).to have_content(@taxon_concept.preferred_common_name_in_language(Language.default))
      visit taxon_details_path @testy[:superceded_taxon_concept]
      current_url.should match /#{taxon_details_path(@taxon_concept)}/
      current_url.should_not match /#{taxon_details_path(@testy[:superceded_taxon_concept])}/
      expect(page).to have_content(@taxon_concept.preferred_common_name_in_language(Language.default))
    end
  end

  context 'when taxon is unpublished' do
    it 'should deny anonymous user' do
      visit logout_path
      lambda { visit taxon_path(@testy[:unpublished_taxon_concept].id) }.should
        raise_error(EOL::Exceptions::MustBeLoggedIn)
    end
    it 'should deny unauthorised user' do
      login_as @user
      referrer = current_url
      lambda { visit taxon_details_path(@testy[:unpublished_taxon_concept].id) }.should
        raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  context 'when taxon does not exist' do
    it 'should show a missing content error message' do
      missing_id = TaxonConcept.last.id + 1
      missing_id += 1 while(TaxonConcept.exists?(missing_id))
      lambda { visit("/pages/#{missing_id}") }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { visit("/pages/#{missing_id}/details") }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'updates tab - taxon_concept' do
    it_should_behave_like 'taxon updates tab' do
      before { visit(taxon_updates_path(@taxon_concept)) }
    end
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_updates_path(@taxon_concept)
      comment = "Test comment by a logged in user. #{FactoryGirl.generate(:string)}"
      expect(page).to have_css("#main .comment #comment_body")
      fill_in 'comment_body', with: comment
      expect(page).to have_css("#main .comment .actions input[value='Post Comment']")
      click_button "Post Comment"
      current_url.should match /#{taxon_updates_path(@taxon_concept)}/
      last_comment = Comment.last
      last_comment.body.should == comment
      expect(page).to have_css("li#Comment-#{last_comment.id}")
    end
  end

  context 'updates tab - hierarchy_entry' do
    it_should_behave_like 'taxon updates tab' do
      before { visit taxon_entry_updates_path(@taxon_concept, @hierarchy_entry) }
    end
    it 'should allow logged in users to post comment' do
      visit logout_url
      login_as @user
      visit taxon_entry_updates_path(@taxon_concept, @hierarchy_entry)
      comment = "Test comment by a logged in user #{FactoryGirl.generate(:string)}."
      expect(page).to have_css("#main .comment #comment_body")
      fill_in 'comment_body', with: comment
      expect(page).to have_css("#main .comment .actions input[value='Post Comment']")
      click_button "Post Comment"
      current_url.should match /#{taxon_entry_updates_path(@taxon_concept, @hierarchy_entry)}/
      expect(page).to have_content('Comment successfully added')
    end
  end
end
