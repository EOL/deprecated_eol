require File.dirname(__FILE__) + '/../spec_helper'

def curator_for_taxon_id(id)
  User.find(:all).each do |user|
    return user if user.can_curate_taxon_id?(id)
  end
end

def create_curator_for_taxon_concept(tc)
  Factory(:curator, :username => 'test_curator',
          :password => 'test_password',
          :curator_hierarchy_entry => HierarchyEntry.gen(:taxon_concept => tc))
end

describe 'Curation' do
  scenario :foundation

  before :each do
    @taxon_concept = build_taxon_concept()
  end

  it 'should not show curation button' do
    request("/pages/#{@taxon_concept.id}").body.should_not have_tag('div#large-image-curator-button')
  end

  it 'should show curation button' do
    curator = create_curator_for_taxon_concept(@taxon_concept)

    login_as( curator ).should redirect_to('/index')

    request("/pages/#{@taxon_concept.id}").body.should have_tag('div#large-image-curator-button')
  end

  it 'should expire taxon from cache' do
    curator = create_curator_for_taxon_concept(@taxon_concept)

    login_as( curator ).should redirect_to('/index')

    ActionController::Base.perform_caching = true

    ActionController::Base.cache_store.should_receive(:delete).any_number_of_times

    request("/data_objects/#{@taxon_concept.images[0].id}/curate", :params => {
            '_method' => 'put',
            'curator_activity_id' => CuratorActivity.disapprove!.id})
  end
end
