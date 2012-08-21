require 'select_with_preload_include'
require 'eol_scenarios'
require 'will_paginate/array'

APPLICATION_DEFAULT_LANGUAGE_ISO = 'en'
$SOLR_SERVER = 'http://localhost:8983/solr/'
$SOLR_TAXON_CONCEPTS_CORE = 'taxon_concepts'
$SOLR_DATA_OBJECTS_CORE = 'data_objects'
$SOLR_SITE_SEARCH_CORE = 'site_search'
$SOLR_COLLECTION_ITEMS_CORE = 'collection_items'
$SOLR_ACTIVITY_LOGS_CORE = 'activity_logs'
$SOLR_BHL_CORE = 'bhl'
$SOLR_DIR    = File.join(Rails.root, 'solr', 'solr')
$INDEX_RECORDS_IN_SOLR_ON_SAVE = true

$CONTENT_SERVERS = ['http://content61.eol.org/']