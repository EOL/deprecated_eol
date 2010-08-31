require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
 curator = build_curator(tc)
 tc.images.last.curator_activity_flag curator, tc.id
 return curator
end

describe 'Curation' do
  
  before(:all) do
    truncate_all_tables
    EolScenario.load :foundation
    Capybara.reset_sessions!
    commit_transactions # Curators are not recognized if transactions are being used, thanks to a lovely
                        # cross-database join.  You can't rollback, because of the EolScenario stuff.  [sigh]
    @common_names_toc_id = TocItem.common_names.id
    # TODO - you REALLY don't want to be doing this before EACH, but...
    @taxon_concept = build_taxon_concept()
    @common_name   = 'boring name'
    @taxon_concept.add_common_name_synonym @common_name, Agent.find(@taxon_concept.acting_curators.first.agent_id), :language => Language.english
    @first_curator = create_curator_for_taxon_concept(@taxon_concept)
    @default_num_curators = @taxon_concept.acting_curators.length
    visit("/pages/#{@taxon_concept.id}")
    @default_page  = source
    visit("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    @non_curator_cname_page = source
    @cn_curator    = create_curator_for_taxon_concept(@taxon_concept)
    @new_name      = 'habrish lammer'
    @taxon_concept.add_common_name_synonym @new_name, Agent.find(@cn_curator.agent_id), :preferred => false, :language => Language.english
    login_capybara(@cn_curator)
    visit("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    @cname_page    = source
    visit('/logout')
    @common_names_toc_id = TocItem.common_names.id
  end

  after(:all) do
    truncate_all_tables
  end

  after(:each) do
    visit('/logout')
  end

  it 'should not show curation button when not logged in' do
    @default_page.should_not have_tag('div#large-image-curator-button')
  end

  it 'should show curation button when logged in as curator' do
    curator = create_curator_for_taxon_concept(@taxon_concept)
    login_capybara(curator)
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div#large-image-curator-button')
  end

  it 'should expire taxon_concept from cache' do
    curator = create_curator_for_taxon_concept(@taxon_concept)
    login_capybara(curator)

    old_cache_val = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true

    ActionController::Base.cache_store.should_receive(:delete).any_number_of_times

    visit("/data_objects/#{@taxon_concept.images[0].id}/curate?_method=put&curator_activity_id=#{CuratorActivity.disapprove.id}")

    $CACHE.clear
    ActionController::Base.perform_caching = old_cache_val
  end

  # --- page citation ---
  
  it 'should confirm that the page doesn\'t have the citation if there is no active curator for the taxon_concept' do
    LastCuratedDate.delete_all
    visit("/pages/#{@taxon_concept.id}")
    body.should_not have_tag('div.number-of-curators')
  end

  it 'should still have a page citation block when there are no curators' do
    LastCuratedDate.delete_all
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div#page-citation')
  end

  it 'should say the page has citation (both lines)' do
    @default_page.should have_tag('div.number-of-curators')
    @default_page.should have_tag('div#page-citation')
  end

  it 'should show the proper number of curators' do
    @default_page.should have_tag('div.number-of-curators', /#{@default_num_curators}/)
  end

  it 'should change the number of curators if another curator curates an image' do
    num_curators = @taxon_concept.acting_curators.length
    curator = create_curator_for_taxon_concept(@taxon_concept)
    @taxon_concept.acting_curators.length.should == num_curators + 1
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div.number-of-curators', /#{num_curators+1}/)
  end

  it 'should change the number of curators if another curator curates a text object' do
    num_curators = @taxon_concept.acting_curators.length
    curator = create_curator_for_taxon_concept(@taxon_concept)
    @taxon_concept.acting_curators.length.should == num_curators + 1
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag("div.number-of-curators", /#{num_curators+1}/)
  end
              
  it 'should have a link from N curators to the citation' do
    @default_page.should have_tag("div.number-of-curators") do
      with_tag('a[href*=?]', /#citation/)
    end
  end
  
  it 'should have a link from name of curator to account page' do
    @default_page.should have_tag('div#page-citation') do
      with_tag('a[href*=?]', /\/account\/show\/#{@taxon_concept.acting_curators.first.id}/)
    end
  end
  
  it 'should still have a curator name in citation after changing clade' do
    @default_page.should have_tag('div#page-citation', /#{@first_curator.family_name}/)
    uu = User.find(@first_curator.id)
    uu.curator_hierarchy_entry_id = uu.curator_hierarchy_entry_id + 1
    uu.save!
    @first_curator = uu
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div#page-citation', /#{@first_curator.family_name}/)
  end


  # I wanted to use a describe() block here, but it was causing build_taxon_concept to fail for some odd reason...

  it 'should show a curator the ability to add a new common name' do
    common_names_toc_id = TocItem.common_names.id
    login_capybara(@first_curator)
    visit("/pages/#{@taxon_concept.id}?category_id=#{common_names_toc_id}")
    body.should have_tag("form#add_common_name")
    body.should have_tag("form.update_common_names")
    visit('/logout')
  end

  it 'should not show editing common name environment if curator is not logged in' do
    visit("/logout")
    visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.common_names.id}")
    body.should_not have_tag("form#add_common_name")
    body.should_not have_tag("form.update_common_names")
  end
  
  # it 'should add a new name' do
  #   tcn_count = TaxonConceptName.count
  #   syn_count = Synonym.count
  #   login_capybara(@first_curator)
  #   language = Language.with_iso_639_1.last

  #   visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.common_names.id}")
  #   body.should have_tag("form#add_common_name")
  #   fill_in "name_name_string", :with => 'Capybara'
  #   select('English', :from => 'name_language')
  #   click_button "Add"
  #   current_url.split('?')[-1].should == "category_id=#{TocItem.common_names.id}"
  #   visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.common_names.id}")
  #   body.should include('Capybara')
  #   TaxonConceptName.count.should == tcn_count + 1
  #   Synonym.count.should == syn_count + 1
  #   Synonym.last.language.should == language
  # end

  # it "should be able to delete a common name using post" do
  #   synonym = @taxon_concept.add_common_name_synonym("New name", @first_curator.agent, :language => Language.english)
  #   tcn_count = TaxonConceptName.count
  #   syn_count = Synonym.count
  #   visit("/pages/#{@taxon_concept.id}/delete_common_name", :method => :post, :params => {:synonym_id => synonym.id, :category_id => @common_names_toc_id, :taxon_concept_id => @taxon_concept.id})
  #   current_path.should == "/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}"
  #   TaxonConceptName.count.should == tcn_count - 1
  #   Synonym.count.should == syn_count - 1
  # end
  
  it 'should be able to curate a concept not in default hierarchy' do
    hierarchy = Hierarchy.gen
    hierarchy_entry = HierarchyEntry.gen(:hierarchy => hierarchy, :taxon_concept => @taxon_concept)
    hierarchy_entry_child = HierarchyEntry.gen(:hierarchy => hierarchy, :parent => hierarchy_entry)
    make_all_nested_sets
    
    @first_curator.can_curate?(hierarchy_entry_child).should == true
  end

end
