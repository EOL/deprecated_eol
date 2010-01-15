require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
 curator = build_curator(tc)
 tc.images.last.curator_activity_flag curator, tc.id
 return curator
end

describe 'Curation' do
  Scenario.load :foundation

  before(:each) do
    commit_transactions # Curators are not recognized if transactions are being used, thanks to a lovely
                        # cross-database join.  You can't rollback, because of the Scenario stuff.  [sigh]
    @common_names_toc_id = TocItem.common_names.id
    # TODO - you REALLY don't want to be doing this before EACH, but...
    @taxon_concept = build_taxon_concept()
    @common_name   = 'boring name'
    @taxon_concept.add_common_name @common_name, Agent.find(@taxon_concept.acting_curators.first.agent_id)
    @first_curator = create_curator_for_taxon_concept(@taxon_concept)
    @default_num_curators = @taxon_concept.acting_curators.length
    @default_page  = request("/pages/#{@taxon_concept.id}").body
    @non_curator_cname_page = request("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}").body
    @cn_curator    = create_curator_for_taxon_concept(@taxon_concept)
    @new_name      = 'habrish lammer'
    @taxon_concept.add_common_name @new_name, Agent.find(@cn_curator.agent_id), :preferred => false
    login_as( @cn_curator ).should redirect_to('/')
    @cname_page    = request("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}").body
    @common_names_toc_id = TocItem.common_names.id
  end

  after(:all) do
    truncate_all_tables
  end

  it 'should not show curation button when not logged in' do
    @default_page.should_not have_tag('div#large-image-curator-button')
  end

  it 'should show curation button when logged in as curator' do
    curator = create_curator_for_taxon_concept(@taxon_concept)

    login_as( curator ).should redirect_to('/')
    
    request("/pages/#{@taxon_concept.id}").body.should have_tag('div#large-image-curator-button')
  end

  it 'should expire taxon_concept from cache' do
    curator = create_curator_for_taxon_concept(@taxon_concept)

    login_as( curator ).should redirect_to('/')

    old_cache_val = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true

    ActionController::Base.cache_store.should_receive(:delete).any_number_of_times

    request("/data_objects/#{@taxon_concept.images[0].id}/curate", :params => {
            '_method' => 'put',
            'curator_activity_id' => CuratorActivity.disapprove!.id})

    Rails.cache.clear
    ActionController::Base.perform_caching = old_cache_val
  end

  # --- page citation ---
  
  it 'should confirm that the page doesn\'t have the citation if there is no active curator for the taxon_concept' do
    LastCuratedDate.delete_all
    the_page = request("/pages/#{@taxon_concept.id}")
    the_page.body.should_not have_tag('div.number-of-curators')
    the_page.body.should_not have_tag('div#page-citation')
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
    request("/pages/#{@taxon_concept.id}").body.should have_tag('div.number-of-curators', /#{num_curators+1}/)
  end

  it 'should change the number of curators if another curator curates a text object' do
    num_curators = @taxon_concept.acting_curators.length
    curator = create_curator_for_taxon_concept(@taxon_concept)
    @taxon_concept.acting_curators.length.should == num_curators + 1
    request("/pages/#{@taxon_concept.id}").body.should have_tag("div.number-of-curators", /#{num_curators+1}/)
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
    request("/pages/#{@taxon_concept.id}").body.should have_tag('div#page-citation', /#{@first_curator.family_name}/)
  end


  # I wanted to use a describe() block here, but it was causing build_taxon_concept to fail for some odd reason...

  it 'should show a curator the ability to add a new common name' do
    common_names_toc_id = TocItem.common_names.id
    login_as( @first_curator ).should redirect_to('/')
    @logged_in_page = request("/pages/#{@taxon_concept.id}?category_id=#{common_names_toc_id}").body
    @logged_in_page.should include('Add a new common name')
  end
  
  it 'should add a new name using post' do
    tcn_count = TaxonConceptName.count
    syn_count = Synonym.count
    login_as(@first_curator).should redirect_to('/')
    language = Language.with_iso_639_1.last
    res = request("/pages/#{@taxon_concept.id}/add_common_name", :method => :post, :params => {:taxon_concept_id => @taxon_concept_id, :name => {:name_string => "new name", :language => language.id, :category_id => @common_names_toc_id}})
    res.should redirect_to("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    TaxonConceptName.count.should == tcn_count + 1
    Synonym.count.should == syn_count + 1
    Synonym.last.language.should == language
  end

  it "should be able to delete a common name using post" do
    name, synonym, taxon_concept_name = @taxon_concept.add_common_name("New name", @first_curator.agent, :language => Language.english)
    tcn_count = TaxonConceptName.count
    syn_count = Synonym.count
    res = request("/pages/#{@taxon_concept.id}/delete_common_name", :method => :post, :params => {:synonym_id => synonym.id, :category_id => @common_names_toc_id, :taxon_concept_id => @taxon_concept.id})
    res.should redirect_to("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    TaxonConceptName.count.should == tcn_count - 1
    Synonym.count.should == syn_count - 1
  end

end
