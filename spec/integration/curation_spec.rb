require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
  curator = build_curator(tc)
  tc.images.last.curator_activity_flag curator, tc.id
  return curator
end

describe 'Curation' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    commit_transactions # Curators are not recognized if transactions are being used, thanks to a lovely
                        # cross-database join.  You can't rollback, because of the EolScenario stuff.  [sigh]
    @common_names_toc_id = TocItem.common_names.id
    # TODO - you REALLY don't want to be doing this before EACH, but...
    @parent_hierarchy_entry = HierarchyEntry.gen(:hierarchy_id => Hierarchy.default.id)
    @taxon_concept   = build_taxon_concept(:parent_hierarchy_entry_id => @parent_hierarchy_entry.id)
    @common_name     = 'boring name'
    @unreviewed_name = Faker::Eol.common_name.firstcap
    @untrusted_name  = Faker::Eol.common_name.firstcap
    @agents_cname    = Faker::Eol.common_name.firstcap
    agent = Agent.find(@taxon_concept.acting_curators.first.agent_id)
    @cn_curator = create_curator_for_taxon_concept(@taxon_concept)
    @common_syn = @taxon_concept.add_common_name_synonym(@common_name, :agent => agent, :language => Language.english,
                                           :vetted => Vetted.unknown, :preferred => false)
    @unreviewed_syn = @taxon_concept.add_common_name_synonym(@unreviewed_name, :agent => agent, :language => Language.english,
                                           :vetted => Vetted.unknown, :preferred => false)
    @untrusted_syn = @taxon_concept.add_common_name_synonym(@untrusted_name, :agent => agent, :language => Language.english,
                                           :vetted => Vetted.untrusted, :preferred => false)
    @agents_syn = @taxon_concept.add_common_name_synonym(@agents_cname, :agent => @cn_curator, :language => Language.english,
                                           :vetted => Vetted.trusted, :preferred => false)
    @first_curator = create_curator_for_taxon_concept(@taxon_concept)
    @default_num_curators = @taxon_concept.acting_curators.length
    visit("/pages/#{@taxon_concept.id}")
    @default_page  = source
    visit("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    @non_curator_cname_page = source
    @new_name   = 'habrish lammer'
    @taxon_concept.add_common_name_synonym @new_name, :agent => Agent.find(@cn_curator.agent_id), :preferred => false, :language => Language.english
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    @cname_page = source
    visit('/logout')
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
    login_as(@first_curator)
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div#large-image-curator-button')
    body.should have_tag('div#curation-overlay')
  end

  it 'should not have a curation panel when not logged in as a curator' do
    visit("/pages/#{@taxon_concept.id}")
    body.should_not have_tag('div#curation-overlay')
  end


  it 'should expire taxon_concept from cache' do
    login_as(@first_curator)
    ActionController.should_receive(:expire_data_object).any_number_of_times.and_return(true)
    #TODO - this isn't working... see the routes file (map.resource :data_objects) for details:
    # visit(curate_data_object_path(@taxon_concept.images[0].id, :curator_activity_id => CuratorActivity.disapprove.id))
    visit("/data_objects/curate/#{@taxon_concept.images[0].id}?vetted_id=#{Vetted.trusted.id}")
  end

  # --- taxa page curators list ---

  it 'should show the curator list link' do
    @default_page.should include('Who can curate this page?')
  end

  it 'should show the curator list link when there has been no activity' do
    LastCuratedDate.delete_all
    visit("/pages/#{@taxon_concept.id}")
    body.should include('Who can curate this page?')
  end

  it 'should show the curator list' do
    visit("/pages/#{@taxon_concept.id}/curators")
    body.should include("The following are curators of")
    body.should include(@cn_curator.family_name)
    body.should include(@cn_curator.given_name)
    body.should include(@first_curator.family_name)
    body.should include(@first_curator.given_name)
  end

  it 'should show an empty curators list on a page with no curators' do
    new_tc = build_taxon_concept
    new_tc.curators.each{|c| c.delete }
    visit("/pages/#{new_tc.id}/curators")
    body.should include("There are no curators of")
  end


  # --- page citation ---

  it 'should confirm that the page doesn\'t have the citation if there is no active curator for the taxon_concept' do
    LastCuratedDate.delete_all
    visit("/pages/#{@taxon_concept.id}")
    body.should_not have_tag('div.number_of_active_curators')
  end

  it 'should still have a page citation block when there are no curators' do
    LastCuratedDate.delete_all
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag('div#page-citation')
  end

  it 'should say the page has citation (both lines)' do
    @taxon_concept.reload
    visit("/pages/#{@taxon_concept.id}")
    body.should include("This page has\n#{@taxon_concept.acting_curators.size}\nactive curators.")
    body.should have_tag('div#page-citation')
  end

  it 'should change the number of curators if another curator curates an image' do
    num_curators = @taxon_concept.acting_curators.length
    curator = create_curator_for_taxon_concept(@taxon_concept)
    @taxon_concept.reload
    @taxon_concept.acting_curators.length.should == num_curators + 1
    visit("/pages/#{@taxon_concept.id}")
    body.should include("This page has\n#{num_curators + 1}\nactive curators.")
  end

  it 'should change the number of curators if another curator curates a text object' do
    @taxon_concept.reload
    num_curators = @taxon_concept.acting_curators.length
    curator = create_curator_for_taxon_concept(@taxon_concept)
    @taxon_concept.reload
    @taxon_concept.acting_curators.length.should == num_curators + 1
    visit("/pages/#{@taxon_concept.id}")
    body.should include("This page has\n#{num_curators + 1}\nactive curators.")
  end

  it 'should have a link from N curators to the citation' do
    @default_page.should have_tag('a[href*=?]', /#citation/)
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

  it 'should display a "view/edit" link next to the common name in the header' do
    login_as(@first_curator)
    visit("/pages/#{@taxon_concept.id}")
    body.should have_tag("div#page-title") do
      with_tag("h2") do
        with_tag("span#curate-common-names", :text => /view\/edit/)
      end
    end
    visit('/logout')
  end

  it 'should show a curator the ability to add a new common name' do
    login_as(@first_curator)
    visit("/pages/#{@taxon_concept.id}?category_id=#{@common_names_toc_id}")
    body.should have_tag("form#add_common_name")
    body.should have_tag("form.update_common_names")
    visit('/logout')
  end

  it 'should show common name sources for curators' do
    @cname_page.should have_tag("div#common_names_wrapper") do
      # Curator link, because we added the common name with agents_synonyms:
      with_tag("a.external_link", :text => /#{@taxon_concept.acting_curators.first.full_name}/)
    end
    visit('/logout')
  end

  # Note that this is essentially the same test as in taxa_page_spec... but we're a curator, now... and it uses a separate
  # view, so it needs to be tested.
  it 'should show all common names trust levels' do
    first_trusted_name =
      @taxon_concept.common_names.select {|n| n.vetted_id == Vetted.trusted.id}.map {|n| n.name.string}.sort[0]
    @cname_page.should have_tag("div#common_names_wrapper") do
      with_tag('td.trusted:nth-child(2)', :text => first_trusted_name)
      with_tag('td.unreviewed:nth-child(2)', :text => @unreviewed_name)
      with_tag('td.untrusted:nth-child(2)', :text => @untrusted_name)
    end
  end

  it 'should show vetting drop-down for common names either NOT added by this curator or added by a CP' do
    @cname_page.should have_tag("div#common_names_wrapper") do
      with_tag("option", :text => 'Trusted')
      with_tag("option", :text => 'Unreviewed')
      with_tag("option", :text => 'Untrusted')
    end
  end

  it 'should show delete link for common names added by this curator' do
    @cname_page.should have_tag("div#common_names_wrapper") do
      with_tag("a[href^=/pages/#{@taxon_concept.id}/delete_common_name]", :text => /del/i)
    end
  end

  it 'should not show editing common name environment if curator is not logged in' do
    visit("/logout")
    visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.common_names.id}")
    body.should_not have_tag("form#add_common_name")
    body.should_not have_tag("form.update_common_names")
  end

  it 'should be able to curate a concept not in default hierarchy' do
    hierarchy = Hierarchy.gen
    hierarchy_entry = HierarchyEntry.gen(:hierarchy => hierarchy, :taxon_concept => @taxon_concept)
    hierarchy_entry_child = HierarchyEntry.gen(:hierarchy => hierarchy, :parent => hierarchy_entry)
    make_all_nested_sets
    flatten_hierarchies
    @first_curator.can_curate?(hierarchy_entry_child).should == true
  end

  it 'should be able to curate a concept when curator hiearchy entry id not in default hierarchy' do
    # If a curator's curator_hierarchy_entry is not in the default hierarchy (think COL 2009 vs COL 2010)
    # and they curate Plants, when they are on a plant page not in their curator hierarchy we had a bug
    # that they couldn't curate that page. This test make sure they can curate things not in their curator hierarchy
    curator_hierarchy = Hierarchy.gen()
    parent_entry_in_curator_hierarchy = HierarchyEntry.gen(:hierarchy => curator_hierarchy, :taxon_concept => @parent_hierarchy_entry.taxon_concept)
    entry_in_curator_hierarchy = HierarchyEntry.gen(:hierarchy => curator_hierarchy, :taxon_concept_id => @taxon_concept.id, :parent_id => parent_entry_in_curator_hierarchy.id)
    entry_not_in_curator_hierarchy = HierarchyEntry.gen(:hierarchy => @parent_hierarchy_entry.hierarchy, :parent => @taxon_concept.entry)
    flatten_hierarchies
    new_curator = build_curator(parent_entry_in_curator_hierarchy)
    HierarchyEntry.connection.execute('COMMIT')
    User.connection.execute('COMMIT')
    new_curator.can_curate?(entry_not_in_curator_hierarchy.taxon_concept).should == true
  end

end
