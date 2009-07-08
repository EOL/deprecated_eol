require File.dirname(__FILE__) + '/../spec_helper'

describe 'Home page' do

  before :all do
    Scenario.load :foundation
    @old_cache_val = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = :memory_store
    Rails.cache.clear
    @taxon_concept = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    @page = RackBox.request('/content/exemplars') # cache the response the homepage gives before changes
  end
  after :all do
    truncate_all_tables
    ActionController::Base.perform_caching = @old_cache_val
  end

  it 'should include the exemplar taxon concept' do
    @page.body.should include(@taxon_concept.scientific_name)
  end

end
