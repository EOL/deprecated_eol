require File.dirname(__FILE__) + '/../spec_helper'

def create_curator_for_taxon_concept(tc)
  curator = build_curator(tc)
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
    @parent_hierarchy_entry = HierarchyEntry.gen(:hierarchy_id => Hierarchy.default.id)
    @taxon_concept   = build_taxon_concept(:parent_hierarchy_entry_id => @parent_hierarchy_entry.id)
    @common_name     = 'boring name'
    @unreviewed_name = Faker::Eol.common_name.firstcap
    @untrusted_name  = Faker::Eol.common_name.firstcap
    @agents_cname    = Faker::Eol.common_name.firstcap
    agent = Agent.find(@taxon_concept.acting_curators.first.agent_id)
    @cn_curator = create_curator_for_taxon_concept(@taxon_concept)
    @common_syn = @taxon_concept.add_common_name_synonym(@common_name, :agent => agent,
                                                         :language => Language.english,
                                                         :vetted => Vetted.unknown, :preferred => false)
    @unreviewed_syn = @taxon_concept.add_common_name_synonym(@unreviewed_name, :agent => agent,
                                                             :language => Language.english,
                                                             :vetted => Vetted.unknown, :preferred => false)
    @untrusted_syn = @taxon_concept.add_common_name_synonym(@untrusted_name, :agent => agent,
                                                            :language => Language.english,
                                                            :vetted => Vetted.untrusted, :preferred => false)
    @agents_syn = @taxon_concept.add_common_name_synonym(@agents_cname, :agent => @cn_curator,
                                                         :language => Language.english,
                                                         :vetted => Vetted.trusted, :preferred => false)
    @first_curator = create_curator_for_taxon_concept(@taxon_concept)
    @default_num_curators = @taxon_concept.acting_curators.length
    make_all_nested_sets
    flatten_hierarchies

    visit("/pages/#{@taxon_concept.id}")
    @default_page  = source
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    @non_curator_cname_page = source
    @new_name   = 'habrish lammer'
    @taxon_concept.add_common_name_synonym @new_name, :agent => Agent.find(@cn_curator.agent_id),
      :preferred => false, :language => Language.english
  end

  after(:all) do
    truncate_all_tables
  end

  after(:each) do
    visit logout_url
  end

  it 'should show a curator the ability to add a new common name' do
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    page.should have_selector("form#new_name")
    page.should have_selector("form.update_common_names")
  end

  it 'should show common name sources for curators' do
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    page.should have_selector(".main_container .update_common_names")
    page.should have_selector(".main_container .update_common_names td", :text => @taxon_concept.acting_curators.first.full_name)
  end
  
  # Note that this is essentially the same test as in taxa_page_spec... but we're a curator, now... and it uses a separate
  # view, so it needs to be tested.
  it 'should show all common names trust levels' do
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    first_trusted_name =
      @taxon_concept.common_names.select {|n| n.vetted_id == Vetted.trusted.id}.map {|n| n.name.string}.sort[0]
    page.should have_selector(".main_container .update_common_names")
    page.should have_selector('.main_container .update_common_names td:nth-child(2)', :text => first_trusted_name.capitalize_all_words)
    page.should have_selector('.main_container .update_common_names td:nth-child(2)', :text => @unreviewed_name.capitalize_all_words)
    page.should have_selector('.main_container .update_common_names td:nth-child(2)', :text => @untrusted_name.capitalize_all_words)
  end
  
  it 'should show vetting drop-down for common names either NOT added by this curator or added by a CP' do
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    page.should have_selector(".main_container .update_common_names")
    page.should have_selector(".main_container .update_common_names td:nth-child(4) option", :text => 'Trusted')
    page.should have_selector(".main_container .update_common_names td:nth-child(4) option", :text => 'Unreviewed')
    page.should have_selector(".main_container .update_common_names td:nth-child(4) option", :text => 'Untrusted')
  end
  
  it 'should show delete link for common names added by this curator' do
    login_as(@cn_curator)
    visit("/pages/#{@taxon_concept.id}/names/common_names")
    page.should have_selector(".main_container .update_common_names")
    page.should have_selector(".main_container .update_common_names a[href^='/pages/#{@taxon_concept.id}/names/delete?']", :text => 'delete')
  end
  
  it 'should not show editing common name environment if curator is not logged in' do
    visit("/logout")
    visit("/pages/#{@taxon_concept.id}?category_id=#{TocItem.common_names.id}")
    body.should_not have_selector("form#add_common_name")
    body.should_not have_selector("form.update_common_names")
  end

end
