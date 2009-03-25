require File.dirname(__FILE__) + '/../spec_helper'

describe 'Home page' do

  before :all do
    Scenario.load :foundation
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = :memory_store
    Rails.cache.clear
    @taxon_concept = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    @page = RackBox.request('/content/exemplars') # cache the response the homepage gives before changes
  end
  after :all do
    truncate_all_tables
    ActionController::Base.perform_caching = false
  end

  it 'should say EOL somewhere' do
    @page.body.should include(@taxon_concept.scientific_name)
  end

#  Trying to reproduce a bug and failing:
#  it 'should load twice without dying' do
#    @page.body.should include(@taxon_concept.scientific_name)
#    page2 = RackBox.request('/content/exemplars') # cache the response the homepage gives before changes
#    page2.body.should include(@taxon_concept.scientific_name)
#  end

end
