require File.dirname(__FILE__) + '/../spec_helper'

describe 'ActivityLogs' do
  before :all do
    truncate_all_tables
    load_foundation_cache
  end

  it 'should log UserAddedData.create' do
    tc = build_taxon_concept
    uad = UserAddedData.gen(:subject => tc)
    visit(taxon_overview_path(tc))
    body.should have_tag("li#UserAddedData-#{uad.id}")
    body.should match /#{uad.user.full_name}.*added data about.*#{uad.predicate_label}.*to.*#{uad.taxon_concept.summary_name}/
    visit(taxon_updates_path(tc))
    body.should have_tag("li#UserAddedData-#{uad.id}")
    body.should match /#{uad.user.full_name}.*added data about.*#{uad.predicate_label}.*to.*#{uad.taxon_concept.summary_name}/
    visit("/")
    body.should have_tag("li#UserAddedData-#{uad.id}")
    body.should match /#{uad.user.full_name}.*added data about.*#{uad.predicate_label}.*to.*#{uad.taxon_concept.summary_name}/
  end
end
