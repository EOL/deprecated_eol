require File.dirname(__FILE__) + '/../spec_helper'

describe 'Home page' do

  before :all do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @old_cache_val = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = :memory_store
    @taxon_concept = build_taxon_concept(:id => 910093) # That ID is one of the (hard-coded) exemplars.
    visit('/content/exemplars') # cache the response the homepage gives before changes
    @body = body
  end

  after :all do
    truncate_all_tables
    ActionController::Base.perform_caching = @old_cache_val
  end

  it 'should include the exemplar taxon concept' do
    @body.should include(@taxon_concept.scientific_name)
  end

end
