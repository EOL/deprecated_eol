require 'select_with_preload_include'
require 'eol_scenarios'
require 'will_paginate/array'

APPLICATION_DEFAULT_LANGUAGE_ISO = 'en'
unless Rails.env.test?
  $SOLR_SERVER = 'http://localhost:8983/solr/'
  $SOLR_SERVER2 = 'http://localhost:4983/solr/'
  $SOLR_DIR    = File.join(Rails.root, 'solr', 'solr')
else
  $SOLR_SERVER = 'http://localhost:8984/solr/'
  $SOLR_DIR    = File.join(Rails.root, 'solr', 'solr_test')
end
$SOLR_TAXON_CONCEPTS_CORE = 'taxon_concepts'
$SOLR_DATA_OBJECTS_CORE = 'data_objects'
$SOLR_SITE_SEARCH_CORE = 'site_search'
$SOLR_COLLECTION_ITEMS_CORE = 'collection_items'
$SOLR_ACTIVITY_LOGS_CORE = 'activity_logs'
$SOLR_BHL_CORE = 'bhl'
$SOLR_TRAITS_CORE='Traits_schema_core'
$SOLR_METADATA_SCHEMA_CORE='Traits_metadata_schema_core'
$INDEX_RECORDS_IN_SOLR_ON_SAVE = true
$RESOURCE_CONTRIBUTIONS_DIR = File.join(Rails.root, 'public', 'resource_contributions')
$VIRTUOSO_CACHING_PERIOD = 12

# NOTE - 
# The following fixes a problem with casting strings to XML which Gemnaisium says we're still vulnerable to:
# ...We should probably remove this once we're sure our version of Rails (and all gems) are of sufficient
# version to handle it.  ...That said, I don't think we ever need to parse params as XML, so I doubt it hurts:
ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete(Mime::XML) 
