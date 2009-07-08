require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require(File.join(RAILS_ROOT, 'spec', 'factories'))
require(File.join(RAILS_ROOT, 'spec', 'eol_spec_helpers'))
require(File.join(RAILS_ROOT, 'spec', 'custom_matchers'))

include EOL::Spec::Helpers

require 'scenarios' 
Scenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

truncate_all_tables_once

EOL::Scenario.load :foundation

Given /^a Taxon Concept (.*)$/ do |tc_id|
  @taxon_concept = build_taxon_concept(:id => tc_id, :common_name => 'vulcan')
end

Given /Taxon Concept (.*) has an image with key "(.*)" harvested from (.*) with a ping_host_url of "(.*)"/ do
  |tc_id, key, name, url|
  @name       = @taxon_concept.taxon_concept_names.first.name # This is what links collection to TC
  @collection = Collection.gen(:ping_host_url => url)
  @mapping    = Mapping.gen(:collection => @collection, :name => @name, :foreign_key => key)
end
