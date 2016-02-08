

Progress: |=======================
  6) KnownUri#by_name should match the first single word
     Failure/Error: expect(KnownUri.by_name('bar').first).to eq(@uri2) # Not 3...
       
       expected: #<RSpec::Mocks::Mock:0x8e88a48 @name=KnownUri(id: integer, uri: string, vetted_id: integer, visibility_id: integer, created_at: datetime, updated_at: datetime, exclude_from_exemplars: boolean, position: integer, uri_type_id: integer, ontology_information_url: string, ontology_source_url: string, group_by_clade: boolean, clade_exemplar: boolean, exemplar_for_same_as: boolean, value_is_text: boolean, hide_from_glossary: boolean, value_is_verbatim: boolean, hide_from_gui: boolean)>
            got: nil
       
       (compared using ==)
     # ./spec/models/known_uri_spec.rb:41:in `block (3 levels) in <top (required)>'

Progress: |=======================
  7) KnownUri#by_name should find an exact match
     Failure/Error: expect(KnownUri.by_name('bar baz').first).to eq(@uri2)
       
       expected: #<RSpec::Mocks::Mock:0x853a4a0 @name=KnownUri(id: integer, uri: string, vetted_id: integer, visibility_id: integer, created_at: datetime, updated_at: datetime, exclude_from_exemplars: boolean, position: integer, uri_type_id: integer, ontology_information_url: string, ontology_source_url: string, group_by_clade: boolean, clade_exemplar: boolean, exemplar_for_same_as: boolean, value_is_text: boolean, hide_from_glossary: boolean, value_is_verbatim: boolean, hide_from_gui: boolean)>
            got: nil
       
       (compared using ==)
     # ./spec/models/known_uri_spec.rb:26:in `block (3 levels) in <top (required)>'

Progress: |=======================
  8) KnownUri#by_name should ignore sparql results that are not URIs
     Failure/Error: EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return(['perfect'])
       (#<EOL::Sparql::VirtuosoClient:0x00000010cb4d68>).all_measurement_type_known_uris(any args)
           expected: 1 time with any arguments
           received: 0 times with any arguments
     # ./spec/models/known_uri_spec.rb:56:in `block (3 levels) in <top (required)>'

Progress: |=======================
  9) KnownUri#by_name should ignore case
     Failure/Error: expect(KnownUri.by_name('foo BAR').first).to eq(@uri3)
       
       expected: #<RSpec::Mocks::Mock:0x9374d40 @name=KnownUri(id: integer, uri: string, vetted_id: integer, visibility_id: integer, created_at: datetime, updated_at: datetime, exclude_from_exemplars: boolean, position: integer, uri_type_id: integer, ontology_information_url: string, ontology_source_url: string, group_by_clade: boolean, clade_exemplar: boolean, exemplar_for_same_as: boolean, value_is_text: boolean, hide_from_glossary: boolean, value_is_verbatim: boolean, hide_from_gui: boolean)>
            got: nil
       
       (compared using ==)
     # ./spec/models/known_uri_spec.rb:31:in `block (3 levels) in <top (required)>'

Progress: |=======================
  10) KnownUri#by_name should ignore symbols
     Failure/Error: expect(KnownUri.by_name('foo$#').first).to eq(@uri3)
       
       expected: #<RSpec::Mocks::Mock:0x9521044 @name=KnownUri(id: integer, uri: string, vetted_id: integer, visibility_id: integer, created_at: datetime, updated_at: datetime, exclude_from_exemplars: boolean, position: integer, uri_type_id: integer, ontology_information_url: string, ontology_source_url: string, group_by_clade: boolean, clade_exemplar: boolean, exemplar_for_same_as: boolean, value_is_text: boolean, hide_from_glossary: boolean, value_is_verbatim: boolean, hide_from_gui: boolean)>
            got: nil
       
       (compared using ==)
     # ./spec/models/known_uri_spec.rb:46:in `block (3 levels) in <top (required)>'

Progress: |=======================
  11) KnownUri#by_name should return empty set with no match
     Failure/Error: EOL::Sparql.connection.should_receive(:all_measurement_type_known_uris).and_return([])
       (#<EOL::Sparql::VirtuosoClient:0x00000010cb4d68>).all_measurement_type_known_uris(any args)
           expected: 1 time with any arguments
           received: 0 times with any arguments
     # ./spec/models/known_uri_spec.rb:51:in `block (3 levels) in <top (required)>'

Progress: |=======================
  12) KnownUri#by_name should ignore extra space
     Failure/Error: expect(KnownUri.by_name('Foo    bar').first).to eq(@uri3)
       
       expected: #<RSpec::Mocks::Mock:0x974b1bc @name=KnownUri(id: integer, uri: string, vetted_id: integer, visibility_id: integer, created_at: datetime, updated_at: datetime, exclude_from_exemplars: boolean, position: integer, uri_type_id: integer, ontology_information_url: string, ontology_source_url: string, group_by_clade: boolean, clade_exemplar: boolean, exemplar_for_same_as: boolean, value_is_text: boolean, hide_from_glossary: boolean, value_is_verbatim: boolean, hide_from_gui: boolean)>
            got: nil
       
       (compared using ==)
     # ./spec/models/known_uri_spec.rb:36:in `block (3 levels) in <top (required)>'

Progress: |===========================
  13) TaxonOverview should know iucn status
     Failure/Error: @overview.iucn_status.should == 'Wunderbar'
       expected: "Wunderbar"
            got: nil (using ==)
     # ./spec/models/taxon_overview_spec.rb:178:in `block (2 levels) in <top (required)>'

Progress: |======================================================
"should use meta description and keyword fields" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071606354793870456.html

  14) CMS page should use meta description and keyword fields
     Failure/Error: page.should have_tag("meta[name='keywords'][content='#{english_translation.meta_keywords}']")
       expected following:
       <!DOCTYPE html>
       <html lang="en" xml:lang="en" xmlns:fb="http://ogp.me/ns/fb#" xmlns:og="http://ogp.me/ns#" xmlns="http://www.w3.org/1999/xhtml">
       <head>
       <title>Test Content Page - Encyclopedia of Life</title>
       <meta charset="utf-8">
       <meta content="text/html; charset=utf-8" http-equiv="Content-type">
       <meta content="true" name="MSSmartTagsPreventParsing">
       <meta content="EOL V2 Beta" name="app_version">
       <meta content="http://www.example.com/info/14" property="og:url">
       <meta content="Encyclopedia of Life" property="og:site_name">
       <meta content="website" property="og:type">
       <meta content="Test Content Page - Encyclopedia of Life" property="og:title">
       <meta content="http://www.example.com/assets/v2/logo_open_graph_default.png" property="og:image">
       <link href="http://www.example.com/info/14" rel="canonical">
       <link href="/assets/favicon.ico" rel="shortcut icon" type="image/vnd.microsoft.icon">
       <link href="/opensearchdescription.xml" rel="search" title="Encyclopedia of Life" type="application/opensearchdescription+xml">
       <link href="/assets/application_pack.css" media="all" rel="stylesheet" type="text/css">
       <!--[if IE 7]>
       <link href="/assets/ie7.css" media="all" rel="stylesheet" type="text/css" />
       <![endif]--><script src="/assets/application.js" type="text/javascript"></script><script src="/assets/_discover.js" type="text/javascript"></script><script src="/assets/jquery.colorbox-min.js" type="text/javascript"></script><link href="/assets/colorbox.css" media="screen" rel="stylesheet" type="text/css">
       <link href="/assets/_discover.css" media="screen" rel="stylesheet" type="text/css">
       </head>
       <body>
       <div id="central">
       <div class="section" role="main">
       <!-- ======================== -->
       <div class="" id="page_heading">
       <div class="site_column">
       <div class="hgroup">
       
       <h1>Test Content Page</h1>
       
       
       </div>
       
       </div>
       </div>
       <div class="cms_page" id="content">
       <div class="site_column">
       <div class="nav">
       <h3>This is Left Content in a Test Content Page</h3>
       </div>
       <div class="article copy">
       <h1>Main Content for Test Content Page ROCKS!</h1>
       </div>
       </div>
       </div>
       
       
       <!-- ======================== -->
       </div>
       </div>
       <div id="banner">
       <div class="site_column">
       <p><strong>Introducing <a href="/traitbank">TraitBank</a>:</strong> search millions of data records on EOL   <small>•</small>   <a href="/traitbank">Learn more</a>   <small>•</small>   <a href="/data_search">Search data</a></p>
       </div>
       </div>
       <div id="header">
       <div class="section">
       <h1><a href="http://www.example.com/" title="This link will take you to the home page of the Encyclopedia of Life Web site">Encyclopedia of Life</a></h1>
       <div class="global_navigation" role="navigation">
       <h2 class="assistive">Global Navigation</h2>
       <ul class="nav">
       <li>
       <a href="/discover">Education</a>
       </li>
       <li>
       <a href="/help">Help</a>
       </li>
       <li>
       <a href="/about">What is EOL?</a>
       </li>
       <li>
       <a href="/news">EOL News</a>
       </li>
       </ul>
       </div>
       
       <div class="actions">
       <div class="language">
       <p class="en" title="This is the currently selected language.">
       <a href="/language"><span>
       English
       </span>
       </a></p>
       <ul>
       <li class="en">
       <a href="http://www.example.com/set_language?language=en&amp;return_to=http%3A%2F%2Fwww.example.com%2Finfo%2F14" title="Switch the site language to English">English</a>
       </li>
       <li class="fr">
       <a href="http://www.example.com/set_language?language=fr&amp;return_to=http%3A%2F%2Fwww.example.com%2Finfo%2F14" title="Switch the site language to Français">Français</a>
       </li>
       <li class="es">
       <a href="http://www.example.com/set_language?language=es&amp;return_to=http%3A%2F%2Fwww.example.com%2Finfo%2F14" title="Switch the site language to Español">Español</a>
       </li>
       <li class="ar">
       <a href="http://www.example.com/set_language?language=ar&amp;return_to=http%3A%2F%2Fwww.example.com%2Finfo%2F14" title="Switch the site language to العربية">العربية</a>
       </li>
       </ul>
       </div>
       </div>
       <form action="http://www.example.com/search?q=" id="simple_search" method="get" role="search">
       <h2 class="assistive">Search the site</h2>
       <fieldset>
       <label class="assistive" for="autocomplete_q">Search EOL</label>
       <div class="text">
       <input data-autocomplete="/search/autocomplete_taxon" data-include-site_search="form#simple_search" data-min-length="3" id="autocomplete_q" maxlength="250" name="q" placeholder="Search EOL ..." size="250" title="Enter a common name or a scientific name of a living creature you would like to know more about. You can also search for EOL members, collections and communities." type="text">
       </div>
       <input data_error="You must enter a search term." data_unchanged="Search EOL ..." name="search" type="submit" value="Go">
       </fieldset>
       </form>
       
       <div class="session join">
       <h3 class="assistive">Login or Create Account</h3>
       <p>Become part of the <abbr title="Encyclopedia of Life">EOL</abbr> community!</p>
       <p><a href="/users/register">Join <abbr title="Encyclopedia of Life">EOL</abbr> now</a></p>
       <p>
       Already a member?
       <a href="/login?return_to=http%3A%2F%2Fwww.example.com%2Finfo%2F14">Sign in</a>
       </p>
       </div>
       
       </div>
       </div>
       <div id="footer" role="contentinfo">
       <div class="section">
       <h2 class="assistive">Site information</h2>
       <div class="wrapper">
       <div class="about">
       <h6>About EOL</h6>
       <ul>
       <li><a href="/about">What is EOL?</a></li>
       <li><a href="/traitbank">What is TraitBank?</a></li>
       <li><a href="http://blog.eol.org">The EOL Blog</a></li>
       <li><a href="/discover">Education</a></li>
       <li><a href="/statistics">Statistics</a></li>
       <li><a href="/info/glossary">Glossary</a></li>
       <li><a href="http://podcast.eol.org/podcast">Podcasts</a></li>
       <li><a href="/info/citing">Citing EOL</a></li>
       <li><a href="/help">Help</a></li>
       <li><a href="/terms_of_use">Terms of Use</a></li>
       <li><a href="/contact_us">Contact Us</a></li>
       </ul>
       </div>
       <div class="learn_more">
       <h6>Learn more about</h6>
       <ul>
       <li>
       <ul>
       <li><a href="/info/animals">Animals</a></li>
       <li><a href="/info/mammals">Mammals</a></li>
       <li><a href="/info/birds">Birds</a></li>
       <li><a href="/info/amphibians">Amphibians</a></li>
       <li><a href="/info/reptiles">Reptiles</a></li>
       <li><a href="/info/fishes">Fishes</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/invertebrates">Invertebrates</a></li>
       <li><a href="/info/crustaceans">Crustaceans</a></li>
       <li><a href="/info/mollusks">Mollusks</a></li>
       <li><a href="/info/insects">Insects</a></li>
       <li><a href="/info/spiders">Spiders</a></li>
       <li><a href="/info/worms">Worms</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/plants">Plants</a></li>
       <li><a href="/info/flowering_plants">Flowering Plants</a></li>
       <li><a href="/info/trees">Trees</a></li>
       </ul>
       <ul>
       <li><a href="/info/fungi">Fungi</a></li>
       <li><a href="/info/mushrooms">Mushrooms</a></li>
       <li><a href="/info/molds">Molds</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/bacteria">Bacteria</a></li>
       </ul>
       <ul>
       <li><a href="/info/algae">Algae</a></li>
       </ul>
       <ul>
       <li><a href="/info/protists">Protists</a></li>
       </ul>
       <ul>
       <li><a href="/info/archaea">Archaea</a></li>
       </ul>
       <ul>
       <li><a href="/info/viruses">Viruses</a></li>
       </ul>
       </li>
       </ul>
       <div class="partners">
       <h6><a href="http://www.biodiversitylibrary.org/">Biodiversity Heritage Library</a></h6>
       <p>Visit the Biodiversity Heritage Library</p>
       </div>
       <ul class="social_media">
       <li><a href="http://twitter.com/#!/EOL" class="twitter" rel="nofollow">Twitter</a></li>
       <li><a href="http://www.facebook.com/encyclopediaoflife" class="facebook" rel="nofollow">Facebook</a></li>
       <li><a href="http://www.flickr.com/groups/encyclopedia_of_life/" class="flickr" rel="nofollow">Flickr</a></li>
       <li><a href="http://www.youtube.com/user/EncyclopediaOfLife/" class="youtube" rel="nofollow">YouTube</a></li>
       <li><a href="http://pinterest.com/eoflife/" class="pinterest" rel="nofollow">Pinterest</a></li>
       <li><a href="http://vimeo.com/groups/encyclopediaoflife" class="vimeo" rel="nofollow">Vimeo</a></li>
       <li><a href="//plus.google.com/+encyclopediaoflife?prsrc=3" class="google_plus" rel="publisher"><img alt="&lt;span class=" translation_missing title="translation missing: en.layouts.footer.google_plus">Google Plus" src="//ssl.gstatic.com/images/icons/gplus-32.png" /&gt;</a></li>
       </ul>
       </div>
       <div class="questions">
       <h6>Tell me more</h6>
       <ul>
       <li><a href="/info/about_biodiversity">What is biodiversity?</a></li>
       <li><a href="/info/species_concepts">What is a species?</a></li>
       <li><a href="/info/discovering_diversity">How are species discovered?</a></li>
       <li><a href="/info/naming_species">How are species named?</a></li>
       <li><a href="/info/taxonomy_phylogenetics">What is a biological classification?</a></li>
       <li><a href="/info/invasive_species">What is an invasive species?</a></li>
       <li><a href="/info/indicator_species">What is an indicator species?</a></li>
       <li><a href="/info/model_organism">What is a model organism?</a></li>
       <li><a href="/info/contribute_research">How can I contribute to research?</a></li>
       <li><a href="/info/evolution">What is evolution?</a></li>
       </ul>
       </div>
       </div>
       </div>
       
       
       </div>
       <script src="/assets/head.load.min.js" type="text/javascript"></script>
       </body>
       </html>
       
       to have at least 1 element matching "meta[name='keywords'][content='Some English keywords']", found 0.
     # ./spec/features/cms_spec.rb:47:in `block (3 levels) in <top (required)>'

Progress: |=============================================================
  15) EOL::Solr::ActivityLog#search_with_pagination should not exclude user_added_data if the user can see it
     Failure/Error: EOL::Solr::ActivityLog.should_receive(:open).with("#{@request_head}foo#{tail}").and_return(@result)
       <EOL::Solr::ActivityLog (class)> received :open with unexpected arguments
         expected: ("http://localhost:8984/solr/activity_logs/select/?wt=json&q=%7B%21lucene%7Dfoo&fl=activity_log_type,activity_log_id,user_id,date_created&group.field=activity_log_unique_key&group.ngroups=true&group=true&rows=30&sort=date_created+desc&start=0")
              got: ("http://localhost:8984/solr/activity_logs/select/?wt=json&q=%7B%21lucene%7Dfoo+NOT+action_keyword%3ADataPointUri+NOT+action_keyword%3AUserAddedData+NOT+activity_log_type%3AUserAddedData&fl=activity_log_type,activity_log_id,user_id,date_created&group.field=activity_log_unique_key&group.ngroups=true&group=true&rows=30&sort=date_created+desc&start=0")
     # ./spec/lib/eol_solr_activity_log_spec.rb:69:in `block (3 levels) in <top (required)>'

Progress: |===================================================================
"renders a JSON response" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071608289872208380.html

  16) API:traits renders a JSON response
     Failure/Error: response.class.should == Hash
       expected: Hash
            got: Array (using ==)
       Diff:
       @@ -1,2 +1,2 @@
       -Hash
       +Array
     # ./spec/features/api/traits_spec.rb:31:in `block (2 levels) in <top (required)>'

Progress: |===================================================================
  17) DataObjectsController GET crop should allow access to curators
     Failure/Error: get :crop, { :id => @image.id, :x => 0, :y => 0, :w => 1 }, { :user => curator, :user_id => curator.id }
     NoMethodError:
       undefined method `has_key?' for 201208092319164:Fixnum
     # ./app/controllers/data_objects_controller.rb:365:in `crop'
     # ./spec/controllers/data_objects_controller_spec.rb:196:in `block (3 levels) in <top (required)>'

Progress: |===================================================================
  18) DataObjectsController POST create should create Link objects and prefix URLs with http://
     Failure/Error: DataObject.exists?(assigns[:data_object]).should == true
       expected: true
            got: false (using ==)
     # ./spec/controllers/data_objects_controller_spec.rb:102:in `block (3 levels) in <top (required)>'

Progress: |===================================================================
  19) DataObjectsController POST create fails validation on invalid link URLs
     Failure/Error: expect(assigns[:data_object]).to have(1).error_on(:source_url)
       expected 1 error on :source_url, got 0
     # ./spec/controllers/data_objects_controller_spec.rb:119:in `block (3 levels) in <top (required)>'

Progress: |=========================================================================
  20) DataSearchFile maintains original unit even when not converted
     Failure/Error: expect(csv).to match(/(500.*[milligrams|#{KnownUri.milligrams.uri}].*){2}/)
       expected "\n" to match /(500.*[milligrams|http:\/\/purl.obolibrary.org\/obo\/UO_0000022].*){2}/
       Diff:
       @@ -1,2 +1 @@
       -/(500.*[milligrams|http:\/\/purl.obolibrary.org\/obo\/UO_0000022].*){2}/
     # ./spec/models/data_search_file_spec.rb:98:in `block (2 levels) in <top (required)>'

Progress: |=========================================================================
  21) DataSearchFile removes hidden rows
     Failure/Error: expect(csv).to match(names.first)
       expected "\n" to match "Comj Kuhip"
       Diff:
       @@ -1,2 +1 @@
       -Comj Kuhip
     # ./spec/models/data_search_file_spec.rb:75:in `block (2 levels) in <top (required)>'

Progress: |=========================================================================
  22) DataSearchFile handles converted units
     Failure/Error: expect(csv).to include("1.0")
       expected "\n" to include "1.0"
       Diff:
       @@ -1,2 +1 @@
       -1.0
     # ./spec/models/data_search_file_spec.rb:86:in `block (2 levels) in <top (required)>'

Progress: |==================================================================================
  23) SolrCore::HierarchyEntries .reindex_hierarchy index an entry with its ancestor kingdom
     Failure/Error: expect(res_count).to eq(2)
       
       expected: 2
            got: 0
       
       (compared using ==)
     # ./spec/models/solr_core/hierarchy_entries_spec.rb:32:in `block (3 levels) in <top (required)>'

Progress: |============================================================================================
  24) CollectionDownloadFile should upload files
     Failure/Error: @collection_file.build_file(@data_point_uris, @lang)
     RuntimeError:
       deprecated
     # ./app/models/data_point_uri.rb:330:in `to_hash'
     # ./app/models/collection_download_file.rb:37:in `block in get_data'
     # ./app/models/collection_download_file.rb:34:in `each'
     # ./app/models/collection_download_file.rb:34:in `get_data'
     # ./app/models/collection_download_file.rb:43:in `write_file'
     # ./app/models/collection_download_file.rb:9:in `build_file'
     # ./spec/models/collection_download_file_spec.rb:46:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display units of measure when explicitly declared" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613173629300083.html

  25) Taxa data tab basic tests should display units of measure when explicitly declared
     Failure/Error: body.should have_selector('span.term', text: 'pounds')
       expected css "span.term" with text "pounds" to return something
     # ./spec/features/taxa_data_tab_spec.rb:86:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display harvested associations" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613219957765028.html

  26) Taxa data tab basic tests should display harvested associations
     Failure/Error: body.should have_selector("table.data tr")
       expected css "table.data tr" to return something
     # ./spec/features/taxa_data_tab_spec.rb:45:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should allow master curators to add data" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613257870553567.html

  27) Taxa data tab basic tests should allow master curators to add data
     Failure/Error: body.should have_tag("form#new_user_added_data")
       expected following:
       <!DOCTYPE html>
       <html lang="en" xml:lang="en" xmlns:fb="http://ogp.me/ns/fb#" xmlns:og="http://ogp.me/ns#" xmlns="http://www.w3.org/1999/xhtml">
       <head>
       <title>Quibusdameli estculpaatvc - Encyclopedia of Life</title>
       <meta charset="utf-8">
       <meta content="text/html; charset=utf-8" http-equiv="Content-type">
       <meta content="No facts are available for Quibusdameli estculpaatvc in the Encyclopedia of Life. EOL invites you to contribute facts about Quibusdameli estculpaatvc." name="description">
       <meta content="Quibusdameli estculpaatvc" name="keywords">
       <meta content="true" name="MSSmartTagsPreventParsing">
       <meta content="EOL V2 Beta" name="app_version">
       <link href="/assets/favicon.ico" rel="shortcut icon" type="image/vnd.microsoft.icon">
       <link href="/opensearchdescription.xml" rel="search" title="Encyclopedia of Life" type="application/opensearchdescription+xml">
       <link href="/assets/application_pack.css" media="all" rel="stylesheet" type="text/css">
       <!--[if IE 7]>
       <link href="/assets/ie7.css" media="all" rel="stylesheet" type="text/css" />
       <![endif]--><script src="/assets/application.js" type="text/javascript"></script>
       </head>
       <body>
       <div id="central">
       <div class="section" role="main">
       <!-- ======================== -->
       
       <div class="with_nav" id="page_heading">
       <div class="site_column">
       <div class="hgroup">
       <h1 class="scientific_name">
       <i>Quibusdameli estculpaatvc</i>
       </h1>
       <div class="copy">
       <p><a href="/pages/7/names">learn more about names for this taxon</a></p>
       </div>
       
       </div>
       <div class="page_actions">
       <ul>
       <li>
       <a href="http://www.example.com/collections/choose_collect_target?item_id=7&amp;item_type=TaxonConcept" class="button collect">Add to a collection</a>
       
       </li>
       <li><a href="http://www.example.com/pages/7/taxon_concept_reindexing" class="button reindex" data-method="post" rel="nofollow">Reindex page</a></li>
       <!-- - if @taxon_data && @taxon_data.downloadable? -->
       <!-- %li -->
       <!-- = link_to I18n.t(:download_data), taxon_overview_path(@taxon_page), :class => 'button', :onclick => 'return false' -->
       </ul>
       </div>
       
       <ul class="nav">
       <li><a href="/pages/7/overview">Overview</a></li>
       <li><a href="/pages/7/details">Detail</a></li>
       <li class="active"><a href="/pages/7/data">Data</a></li>
       <li><a href="/pages/7/media">90 Media</a></li>
       <li><a href="/pages/7/maps">0 Maps</a></li>
       <li><a href="/pages/7/names">Names</a></li>
       <li><a href="/pages/7/communities">Community</a></li>
       <li><a href="/pages/7/resources">Resources</a></li>
       <li><a href="/pages/7/literature">Literature</a></li>
       <li><a href="/pages/7/updates">Updates</a></li>
       <li><a href="/pages/7/worklist">Worklist</a></li>
       </ul>
       </div>
       </div>
       <div id="content">
       <div class="site_column">
       <div class="data" id="tabs_sidebar">
       <ul class="subtabs tabs with_icons">
       <li class="active all"><a href="/pages/7/data">All</a></li>
       <li class="about"><a href="/pages/7/data/about">About</a></li>
       </ul>
       </div>
       <div class="main_container" id="taxon_data">
       <h3 class="assistive">Data about &lt;i&gt;Quibusdameli estculpaatvc&lt;/i&gt;</h3>
       <div class="about_subtab" style="display: none">
       <h3>About Data on EOL</h3>
       <div class="explain">
       <p><a href="/info/traitbank">TraitBank</a> gathers data and metadata from multiple sources into a single, fully-referenced and semantically accessible taxon-centric view.</p>
       <p><a href="/contact_us?subject=Contribute">Contact us</a> for more information on sharing data sets with EOL or to recommend a data set for inclusion into TraitBank.</p>
       <p><a href="/users/register">Register for a free account</a> or <a href="/login?return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata">sign in</a> to comment on the data.</p>
       <p>Funding for the development of EOL computable data functionality provided by the Alfred P. Sloan Foundation, the John D. and Catherine T. MacArthur Foundation, and from EOL users around the world. <a href="/contact_us?subject=TraitBank">Contact the EOL Secretariat</a> for more information on TraitBank.</p>
       </div>
       </div>
       <div class="help_text">
       <p>
       <a href="/info/traitbank">TraitBank</a> assembles data records from many providers. Select a row for more details about the record, or <a href="/data_search?taxon_concept_id=7">search TraitBank</a>.
       </p>
       </div>
       </div>
       
       <div class="disclaimer copy">
       <h3 class="assistive">Disclaimer</h3>
       <p>EOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.</p>
       <p>To request an improvement, please leave a comment on the page. Thank you!</p>
       </div>
       </div>
       </div>
       
       <!-- ======================== -->
       </div>
       </div>
       <div id="banner">
       <div class="site_column">
       <p><strong>Introducing <a href="/traitbank">TraitBank</a>:</strong> search millions of data records on EOL   <small>•</small>   <a href="/traitbank">Learn more</a>   <small>•</small>   <a href="/data_search">Search data</a></p>
       </div>
       </div>
       <div id="header">
       <div class="section">
       <h1><a href="http://www.example.com/" title="This link will take you to the home page of the Encyclopedia of Life Web site">Encyclopedia of Life</a></h1>
       <div class="global_navigation" role="navigation">
       <h2 class="assistive">Global Navigation</h2>
       <ul class="nav">
       <li>
       <a href="/discover">Education</a>
       </li>
       <li>
       <a href="/help">Help</a>
       </li>
       <li>
       <a href="/about">What is EOL?</a>
       </li>
       <li>
       <a href="/news">EOL News</a>
       </li>
       </ul>
       </div>
       
       <div class="actions">
       <div class="language">
       <p class="en" title="This is the currently selected language.">
       <a href="/language"><span>
       English
       </span>
       </a></p>
       <ul>
       <li class="en">
       <a href="http://www.example.com/set_language?language=en&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata" title="Switch the site language to English">English</a>
       </li>
       <li class="fr">
       <a href="http://www.example.com/set_language?language=fr&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata" title="Switch the site language to Français">Français</a>
       </li>
       <li class="es">
       <a href="http://www.example.com/set_language?language=es&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata" title="Switch the site language to Español">Español</a>
       </li>
       <li class="ar">
       <a href="http://www.example.com/set_language?language=ar&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata" title="Switch the site language to العربية">العربية</a>
       </li>
       </ul>
       </div>
       </div>
       <form action="http://www.example.com/search?q=" id="simple_search" method="get" role="search">
       <h2 class="assistive">Search the site</h2>
       <fieldset>
       <label class="assistive" for="autocomplete_q">Search EOL</label>
       <div class="text">
       <input data-autocomplete="/search/autocomplete_taxon" data-include-site_search="form#simple_search" data-min-length="3" id="autocomplete_q" maxlength="250" name="q" placeholder="Search EOL ..." size="250" title="Enter a common name or a scientific name of a living creature you would like to know more about. You can also search for EOL members, collections and communities." type="text">
       </div>
       <input data_error="You must enter a search term." data_unchanged="Search EOL ..." name="search" type="submit" value="Go">
       </fieldset>
       </form>
       
       <div class="session signed_in">
       <h2 class="assistive">Account Information</h2>
       <ul class="notifications">
       <li><a href="/users/12/newsfeed/comments" title="10 comments">10<span class="assistive"> comments</span></a></li>
       <li><a href="/users/12/newsfeed" title="0 notifications">0<span class="assistive"> notifications</span></a></li>
       </ul>
       <a href="/users/12/newsfeed"><img alt="Profile picture for member Kailfr McCullougx" height="48" src="/assets/localhostcontent/2011/11/02/11/31069_88_88.jpg" width="48"></a>
       <div class="details">
       <p><strong>Kailfr</strong>
       <br></p>
       <ul class="user_links">
       <li><a href="/users/12">Profile</a></li>
       <li><a href="/curators">Curators</a></li>
       <li><a href="http://www.example.com/logout?return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F7%2Fdata">Sign Out</a></li>
       </ul>
       </div>
       </div>
       
       </div>
       </div>
       <div id="footer" role="contentinfo">
       <div class="section">
       <h2 class="assistive">Site information</h2>
       <div class="wrapper">
       <div class="about">
       <h6>About EOL</h6>
       <ul>
       <li><a href="/about">What is EOL?</a></li>
       <li><a href="/traitbank">What is TraitBank?</a></li>
       <li><a href="http://blog.eol.org">The EOL Blog</a></li>
       <li><a href="/discover">Education</a></li>
       <li><a href="/statistics">Statistics</a></li>
       <li><a href="/info/glossary">Glossary</a></li>
       <li><a href="http://podcast.eol.org/podcast">Podcasts</a></li>
       <li><a href="/info/citing">Citing EOL</a></li>
       <li><a href="/help">Help</a></li>
       <li><a href="/terms_of_use">Terms of Use</a></li>
       <li><a href="/contact_us">Contact Us</a></li>
       </ul>
       </div>
       <div class="learn_more">
       <h6>Learn more about</h6>
       <ul>
       <li>
       <ul>
       <li><a href="/info/animals">Animals</a></li>
       <li><a href="/info/mammals">Mammals</a></li>
       <li><a href="/info/birds">Birds</a></li>
       <li><a href="/info/amphibians">Amphibians</a></li>
       <li><a href="/info/reptiles">Reptiles</a></li>
       <li><a href="/info/fishes">Fishes</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/invertebrates">Invertebrates</a></li>
       <li><a href="/info/crustaceans">Crustaceans</a></li>
       <li><a href="/info/mollusks">Mollusks</a></li>
       <li><a href="/info/insects">Insects</a></li>
       <li><a href="/info/spiders">Spiders</a></li>
       <li><a href="/info/worms">Worms</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/plants">Plants</a></li>
       <li><a href="/info/flowering_plants">Flowering Plants</a></li>
       <li><a href="/info/trees">Trees</a></li>
       </ul>
       <ul>
       <li><a href="/info/fungi">Fungi</a></li>
       <li><a href="/info/mushrooms">Mushrooms</a></li>
       <li><a href="/info/molds">Molds</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/bacteria">Bacteria</a></li>
       </ul>
       <ul>
       <li><a href="/info/algae">Algae</a></li>
       </ul>
       <ul>
       <li><a href="/info/protists">Protists</a></li>
       </ul>
       <ul>
       <li><a href="/info/archaea">Archaea</a></li>
       </ul>
       <ul>
       <li><a href="/info/viruses">Viruses</a></li>
       </ul>
       </li>
       </ul>
       <div class="partners">
       <h6><a href="http://www.biodiversitylibrary.org/">Biodiversity Heritage Library</a></h6>
       <p>Visit the Biodiversity Heritage Library</p>
       </div>
       <ul class="social_media">
       <li><a href="http://twitter.com/#!/EOL" class="twitter" rel="nofollow">Twitter</a></li>
       <li><a href="http://www.facebook.com/encyclopediaoflife" class="facebook" rel="nofollow">Facebook</a></li>
       <li><a href="http://www.flickr.com/groups/encyclopedia_of_life/" class="flickr" rel="nofollow">Flickr</a></li>
       <li><a href="http://www.youtube.com/user/EncyclopediaOfLife/" class="youtube" rel="nofollow">YouTube</a></li>
       <li><a href="http://pinterest.com/eoflife/" class="pinterest" rel="nofollow">Pinterest</a></li>
       <li><a href="http://vimeo.com/groups/encyclopediaoflife" class="vimeo" rel="nofollow">Vimeo</a></li>
       <li><a href="//plus.google.com/+encyclopediaoflife?prsrc=3" class="google_plus" rel="publisher"><img alt="&lt;span class=" translation_missing title="translation missing: en.layouts.footer.google_plus">Google Plus" src="//ssl.gstatic.com/images/icons/gplus-32.png" /&gt;</a></li>
       </ul>
       </div>
       <div class="questions">
       <h6>Tell me more</h6>
       <ul>
       <li><a href="/info/about_biodiversity">What is biodiversity?</a></li>
       <li><a href="/info/species_concepts">What is a species?</a></li>
       <li><a href="/info/discovering_diversity">How are species discovered?</a></li>
       <li><a href="/info/naming_species">How are species named?</a></li>
       <li><a href="/info/taxonomy_phylogenetics">What is a biological classification?</a></li>
       <li><a href="/info/invasive_species">What is an invasive species?</a></li>
       <li><a href="/info/indicator_species">What is an indicator species?</a></li>
       <li><a href="/info/model_organism">What is a model organism?</a></li>
       <li><a href="/info/contribute_research">How can I contribute to research?</a></li>
       <li><a href="/info/evolution">What is evolution?</a></li>
       </ul>
       </div>
       </div>
       </div>
       
       
       </div>
       <script src="/assets/head.load.min.js" type="text/javascript"></script><script type="application/ld+json">
       {
         "@graph": [
           {
             "@id": "http://eol.org/pages/7",
             "@type": "dwc:Taxon",
             "dwc:scientificName": "Quibusdameli estculpaatvc Linn",
             "dwc:taxonRank": null
           }
         ],
         "@context": {
           "dwc:taxonID": {
             "@type": "@id"
           },
           "dwc:resourceID": {
             "@type": "@id"
           },
           "dwc:relatedResourceID": {
             "@type": "@id"
           },
           "dwc:relationshipOfResource": {
             "@type": "@id"
           },
           "dwc:vernacularName": {
             "@container": "@language"
           },
           "eol:associationType": {
             "@type": "@id"
           },
           "rdfs:label": {
             "@container": "@language"
           },
           "dc": "http://purl.org/dc/terms/",
           "dwc": "http://rs.tdwg.org/dwc/terms/",
           "eol": "http://eol.org/schema/",
           "eolterms": "http://eol.org/schema/terms/",
           "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
           "gbif": "http://rs.gbif.org/terms/1.0/",
           "foaf": "http://xmlns.com/foaf/0.1/"
         }
       }
       
       </script>
       </body>
       </html>
       
       to have at least 1 element matching "form#new_user_added_data", found 0.
     # ./spec/features/taxa_data_tab_spec.rb:109:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display user added data" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613273712653249.html

  28) Taxa data tab basic tests should display user added data
     Failure/Error: body.should have_selector("table.data tr")
       expected css "table.data tr" to return something
     # ./spec/features/taxa_data_tab_spec.rb:54:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display units of measure when implied by measurement type" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613308641927368.html

  29) Taxa data tab basic tests should display units of measure when implied by measurement type
     Failure/Error: body.should have_selector("table.data td[headers='predicate_http___eol_org_time'] span", text: '50')
       expected css "table.data td[headers='predicate_http___eol_org_time'] span" with text "50" to return something
     # ./spec/features/taxa_data_tab_spec.rb:94:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display harvested measurements" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613321293358352.html

  30) Taxa data tab basic tests should display harvested measurements
     Failure/Error: body.should have_selector("table.data tr")
       expected css "table.data tr" to return something
     # ./spec/features/taxa_data_tab_spec.rb:36:in `block (2 levels) in <top (required)>'

Progress: |==============================================================================================
"should display known uri labels when available" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071613348819095356.html

  31) Taxa data tab basic tests should display known uri labels when available
     Failure/Error: body.should have_selector("table.data td span", text: 'Massive')
       expected css "table.data td span" with text "Massive" to return something
     # ./spec/features/taxa_data_tab_spec.rb:65:in `block (2 levels) in <top (required)>'

Progress: |================================================================================================
  32) taxa/overview/show logged out should NOT show quick facts when the user doesn't have access (FOR NOW)
     Failure/Error: expect(rendered).to_not match /#{I18n.t(:data_summary_header_with_count, count: 0)}/
       expected "<div id='taxon'>\n<div class='gallery' id='media_summary'>\n<h3 class='assistive'>Media</h3>\n<div class='images'>\n<div class='image'>\n<img alt=\"\" src=\"/assets/v2/img_taxon-placeholder.png\" />\n<div class='attribution'>\n<div class='copy'>\n<p>No one has contributed any images to this page yet.</p>\n<p><a href=\"/info/contribute\">Learn how to contribute images to EOL.</a></p>\n</div>\n</div>\n</div>\n</div>\n<p class='all'>\n<a href=\"/pages/%23%5BRSpec::Mocks::Mock:0x9900480%20@name=TaxonOverview%5D/media\">See all media</a>\n<br>\n\n</p>\n</div>\n<div class='neutral' id='iucn_status'>\n<h3><abbr title=\"International Union for Conservation of Nature\">IUCN</abbr> threat status:</h3>\n<p><a href=\"http://iucn.org\" rel=\"nofollow\" title=\"This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.\">lucky</a></p>\n</div>\n<div class='article overview' id='text_summary'>\n<div class='header'>\n<h3>Brief summary</h3>\n</div>\n<div class='empty'>\n<p>No one has contributed a brief summary to this page yet.</p>\n<a href=\"/pages/%23%5BRSpec::Mocks::Mock:0x9900480%20@name=TaxonOverview%5D/data_objects/new\" class=\"button\">Add a brief summary to this page</a>\n</div>\n</div>\n<div class='article half list clear' id='collections_summary'>\n<div class='header'>\n<h3>Present in 0 collections</h3>\n</div>\n<div class='empty'>\n<p>\nThis page isn't in any collections yet.\n<fieldset class='actions'>\n<a href=\"http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock\" class=\"button\">Add to a collection</a>\n\n</fieldset>\n</p>\n</div>\n</div>\n<div class='article half list' id='communities_summary'>\n<div class='header'>\n<h3>Belongs to 0 communities</h3>\n</div>\n<div class='empty'>\n<p>This taxon hasn't been featured in any communities yet.</p>\n<p><a href=\"/info/communities\">Learn more about Communities</a></p>\n</div>\n</div>\n</div>\n<div id='sidebar'>\n<div class='article' id='data_summary'>\n<div class='header'>\n<h3>EOL has no trait data</h3>\n</div>\n<div class='empty'>\n<p>\nNo one has contributed data records for Aus bus yet.\n<a href=\"http://test.host/info/contribute#data\">Learn how to contribute.</a>\n</p>\n</div>\n</div>\n\n<div class='article' id='classification_tree'>\n<div class='header'>\n<h3>EOL has no classifications for this taxon</h3>\n</div>\n<div class='browsable classifications' id='classification_browser'>\n<li>\nSorry, the data for this node is missing.\n</li>\n\n</div>\n</div>\n<div class='article list' id='curators_summary'>\n<div class='header'>\n<h3>Reviewed by 0 curators</h3>\n<a href=\"/curators\">Learn how to curate</a>\n</div>\n<div class='empty'>\n<p>Our curators haven't taken any action on this page yet.</p>\n</div>\n</div>\n<div class='article list updates'>\n<div class='header'>\n<h3>Latest updates</h3>\n</div>\n<div class='empty'>\n<p>No one has provided updates yet.</p>\n</div>\n\n<h4 class='assistive'>Add a new comment</h4>\n<form accept-charset=\"UTF-8\" action=\"/comments.html\" class=\"comment\" id=\"new_comment\" method=\"post\"><div style=\"margin:0;padding:0;display:inline\"><input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\" /></div><input id=\"comment_parent_type\" name=\"comment[parent_type]\" type=\"hidden\" value=\"RSpec::Mocks::Mock\" />\n<input id=\"comment_parent_id\" name=\"comment[parent_id]\" type=\"hidden\" value=\"1\" />\n<input id=\"comment_reply_to_type\" name=\"comment[reply_to_type]\" type=\"hidden\" />\n<input id=\"comment_reply_to_id\" name=\"comment[reply_to_id]\" type=\"hidden\" />\n<input id=\"return_to\" name=\"return_to\" type=\"hidden\" value=\"http://yes.we/really_have/this-helper.method\" />\n<input id=\"submit_to\" name=\"submit_to\" type=\"hidden\" value=\"/comments/create\" />\n<fieldset>\n<img alt=\"\" src=\"/assets/v2/logos/user_default.png\" />\n<div>\n<label class=\"assistive\" for=\"comment_body\">Your comment</label>\n<textarea cols=\"60\" id=\"comment_body\" name=\"comment[body]\" rows=\"3\">\n</textarea>\n</div>\n</fieldset>\n<fieldset class='actions'>\n<input data-cancel=\"Cancel\" data-reply=\"Leave Reply\" name=\"commit\" type=\"submit\" value=\"Post Comment\" />\n</fieldset>\n</form>\n\n\n</div>\n</div>\n" not to match /EOL has no trait data/
       Diff:
       @@ -1,2 +1,122 @@
       -/EOL has no trait data/
       +<div id='taxon'>
       +<div class='gallery' id='media_summary'>
       +<h3 class='assistive'>Media</h3>
       +<div class='images'>
       +<div class='image'>
       +<img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       +<div class='attribution'>
       +<div class='copy'>
       +<p>No one has contributed any images to this page yet.</p>
       +<p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       +</div>
       +</div>
       +</div>
       +</div>
       +<p class='all'>
       +<a href="/pages/%23%5BRSpec::Mocks::Mock:0x9900480%20@name=TaxonOverview%5D/media">See all media</a>
       +<br>
       +
       +</p>
       +</div>
       +<div class='neutral' id='iucn_status'>
       +<h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       +<p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       +</div>
       +<div class='article overview' id='text_summary'>
       +<div class='header'>
       +<h3>Brief summary</h3>
       +</div>
       +<div class='empty'>
       +<p>No one has contributed a brief summary to this page yet.</p>
       +<a href="/pages/%23%5BRSpec::Mocks::Mock:0x9900480%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       +</div>
       +</div>
       +<div class='article half list clear' id='collections_summary'>
       +<div class='header'>
       +<h3>Present in 0 collections</h3>
       +</div>
       +<div class='empty'>
       +<p>
       +This page isn't in any collections yet.
       +<fieldset class='actions'>
       +<a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       +
       +</fieldset>
       +</p>
       +</div>
       +</div>
       +<div class='article half list' id='communities_summary'>
       +<div class='header'>
       +<h3>Belongs to 0 communities</h3>
       +</div>
       +<div class='empty'>
       +<p>This taxon hasn't been featured in any communities yet.</p>
       +<p><a href="/info/communities">Learn more about Communities</a></p>
       +</div>
       +</div>
       +</div>
       +<div id='sidebar'>
       +<div class='article' id='data_summary'>
       +<div class='header'>
       +<h3>EOL has no trait data</h3>
       +</div>
       +<div class='empty'>
       +<p>
       +No one has contributed data records for Aus bus yet.
       +<a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       +</p>
       +</div>
       +</div>
       +
       +<div class='article' id='classification_tree'>
       +<div class='header'>
       +<h3>EOL has no classifications for this taxon</h3>
       +</div>
       +<div class='browsable classifications' id='classification_browser'>
       +<li>
       +Sorry, the data for this node is missing.
       +</li>
       +
       +</div>
       +</div>
       +<div class='article list' id='curators_summary'>
       +<div class='header'>
       +<h3>Reviewed by 0 curators</h3>
       +<a href="/curators">Learn how to curate</a>
       +</div>
       +<div class='empty'>
       +<p>Our curators haven't taken any action on this page yet.</p>
       +</div>
       +</div>
       +<div class='article list updates'>
       +<div class='header'>
       +<h3>Latest updates</h3>
       +</div>
       +<div class='empty'>
       +<p>No one has provided updates yet.</p>
       +</div>
       +
       +<h4 class='assistive'>Add a new comment</h4>
       +<form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       +<input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       +<input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       +<input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       +<input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       +<input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       +<fieldset>
       +<img alt="" src="/assets/v2/logos/user_default.png" />
       +<div>
       +<label class="assistive" for="comment_body">Your comment</label>
       +<textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       +</textarea>
       +</div>
       +</fieldset>
       +<fieldset class='actions'>
       +<input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       +</fieldset>
       +</form>
       +
       +
       +</div>
       +</div>
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:64:in `block (3 levels) in <top (required)>'

Progress: |================================================================================================
  33) taxa/overview/show logged with see_data permission should show statistical method
     Failure/Error: expect(rendered).to have_tag('span.stat', text: /Itsmethod/)
       expected following:
       <div id='taxon'>
       <div class='gallery' id='media_summary'>
       <h3 class='assistive'>Media</h3>
       <div class='images'>
       <div class='image'>
       <img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       <div class='attribution'>
       <div class='copy'>
       <p>No one has contributed any images to this page yet.</p>
       <p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       </div>
       </div>
       </div>
       </div>
       <p class='all'>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9afbbcc%20@name=TaxonOverview%5D/media">See all media</a>
       <br>
       
       </p>
       </div>
       <div class='neutral' id='iucn_status'>
       <h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       <p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       </div>
       <div class='article overview' id='text_summary'>
       <div class='header'>
       <h3>Brief summary</h3>
       </div>
       <div class='empty'>
       <p>No one has contributed a brief summary to this page yet.</p>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9afbbcc%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       </div>
       </div>
       <div class='article half list clear' id='collections_summary'>
       <div class='header'>
       <h3>Present in 0 collections</h3>
       </div>
       <div class='empty'>
       <p>
       This page isn't in any collections yet.
       <fieldset class='actions'>
       <a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       
       </fieldset>
       </p>
       </div>
       </div>
       <div class='article half list' id='communities_summary'>
       <div class='header'>
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class='empty'>
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id='sidebar'>
       <div class='article' id='data_summary'>
       <div class='header'>
       <h3>EOL has no trait data</h3>
       </div>
       <div class='empty'>
       <p>
       No one has contributed data records for Aus bus yet.
       <a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class='article' id='classification_tree'>
       <div class='header'>
       <h3>EOL has no classifications for this taxon</h3>
       </div>
       <div class='browsable classifications' id='classification_browser'>
       <li>
       Sorry, the data for this node is missing.
       </li>
       
       </div>
       </div>
       <div class='article list' id='curators_summary'>
       <div class='header'>
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class='empty'>
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class='article list updates'>
       <div class='header'>
       <h3>Latest updates</h3>
       </div>
       <div class='empty'>
       <p>No one has provided updates yet.</p>
       </div>
       
       <h4 class='assistive'>Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       <input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       <input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       <input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       <input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       <input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       <fieldset>
       <img alt="Your profile picture, if you have provided one." src="/assets/whatever" title="Your profile picture and name will appear next to your comment in listings." />
       <div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       </textarea>
       </div>
       </fieldset>
       <fieldset class='actions'>
       <input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       </fieldset>
       </form>
       
       
       </div>
       </div>
       
       to have at least 1 element matching "span.stat", found 0.
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:104:in `block (3 levels) in <top (required)>'

Progress: |================================================================================================
  34) taxa/overview/show logged with see_data permission should show combinations of context modifiers
     Failure/Error: expect(rendered).to have_tag('span.stat', text: /Itsmethod, Itslifestage, Itssex/)
       expected following:
       <div id='taxon'>
       <div class='gallery' id='media_summary'>
       <h3 class='assistive'>Media</h3>
       <div class='images'>
       <div class='image'>
       <img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       <div class='attribution'>
       <div class='copy'>
       <p>No one has contributed any images to this page yet.</p>
       <p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       </div>
       </div>
       </div>
       </div>
       <p class='all'>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9bc3dd4%20@name=TaxonOverview%5D/media">See all media</a>
       <br>
       
       </p>
       </div>
       <div class='neutral' id='iucn_status'>
       <h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       <p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       </div>
       <div class='article overview' id='text_summary'>
       <div class='header'>
       <h3>Brief summary</h3>
       </div>
       <div class='empty'>
       <p>No one has contributed a brief summary to this page yet.</p>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9bc3dd4%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       </div>
       </div>
       <div class='article half list clear' id='collections_summary'>
       <div class='header'>
       <h3>Present in 0 collections</h3>
       </div>
       <div class='empty'>
       <p>
       This page isn't in any collections yet.
       <fieldset class='actions'>
       <a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       
       </fieldset>
       </p>
       </div>
       </div>
       <div class='article half list' id='communities_summary'>
       <div class='header'>
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class='empty'>
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id='sidebar'>
       <div class='article' id='data_summary'>
       <div class='header'>
       <h3>EOL has no trait data</h3>
       </div>
       <div class='empty'>
       <p>
       No one has contributed data records for Aus bus yet.
       <a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class='article' id='classification_tree'>
       <div class='header'>
       <h3>EOL has no classifications for this taxon</h3>
       </div>
       <div class='browsable classifications' id='classification_browser'>
       <li>
       Sorry, the data for this node is missing.
       </li>
       
       </div>
       </div>
       <div class='article list' id='curators_summary'>
       <div class='header'>
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class='empty'>
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class='article list updates'>
       <div class='header'>
       <h3>Latest updates</h3>
       </div>
       <div class='empty'>
       <p>No one has provided updates yet.</p>
       </div>
       
       <h4 class='assistive'>Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       <input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       <input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       <input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       <input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       <input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       <fieldset>
       <img alt="Your profile picture, if you have provided one." src="/assets/whatever" title="Your profile picture and name will appear next to your comment in listings." />
       <div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       </textarea>
       </div>
       </fieldset>
       <fieldset class='actions'>
       <input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       </fieldset>
       </form>
       
       
       </div>
       </div>
       
       to have at least 1 element matching "span.stat", found 0.
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:131:in `block (3 levels) in <top (required)>'

Progress: |================================================================================================
  35) taxa/overview/show logged with see_data permission should have a show more link when a row has more data
     Failure/Error: expect(rendered).to have_tag('td a', text: 'more')
       expected following:
       <div id='taxon'>
       <div class='gallery' id='media_summary'>
       <h3 class='assistive'>Media</h3>
       <div class='images'>
       <div class='image'>
       <img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       <div class='attribution'>
       <div class='copy'>
       <p>No one has contributed any images to this page yet.</p>
       <p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       </div>
       </div>
       </div>
       </div>
       <p class='all'>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x8bee648%20@name=TaxonOverview%5D/media">See all media</a>
       <br>
       
       </p>
       </div>
       <div class='neutral' id='iucn_status'>
       <h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       <p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       </div>
       <div class='article overview' id='text_summary'>
       <div class='header'>
       <h3>Brief summary</h3>
       </div>
       <div class='empty'>
       <p>No one has contributed a brief summary to this page yet.</p>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x8bee648%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       </div>
       </div>
       <div class='article half list clear' id='collections_summary'>
       <div class='header'>
       <h3>Present in 0 collections</h3>
       </div>
       <div class='empty'>
       <p>
       This page isn't in any collections yet.
       <fieldset class='actions'>
       <a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       
       </fieldset>
       </p>
       </div>
       </div>
       <div class='article half list' id='communities_summary'>
       <div class='header'>
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class='empty'>
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id='sidebar'>
       <div class='article' id='data_summary'>
       <div class='header'>
       <h3>EOL has no trait data</h3>
       </div>
       <div class='empty'>
       <p>
       No one has contributed data records for Aus bus yet.
       <a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class='article' id='classification_tree'>
       <div class='header'>
       <h3>EOL has no classifications for this taxon</h3>
       </div>
       <div class='browsable classifications' id='classification_browser'>
       <li>
       Sorry, the data for this node is missing.
       </li>
       
       </div>
       </div>
       <div class='article list' id='curators_summary'>
       <div class='header'>
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class='empty'>
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class='article list updates'>
       <div class='header'>
       <h3>Latest updates</h3>
       </div>
       <div class='empty'>
       <p>No one has provided updates yet.</p>
       </div>
       
       <h4 class='assistive'>Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       <input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       <input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       <input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       <input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       <input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       <fieldset>
       <img alt="Your profile picture, if you have provided one." src="/assets/whatever" title="Your profile picture and name will appear next to your comment in listings." />
       <div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       </textarea>
       </div>
       </fieldset>
       <fieldset class='actions'>
       <input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       </fieldset>
       </form>
       
       
       </div>
       </div>
       
       to have at least 1 element matching "td a", found 0.
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:95:in `block (3 levels) in <top (required)>'

Progress: |================================================================================================
  36) taxa/overview/show logged with see_data permission should show life stage
     Failure/Error: expect(rendered).to have_tag('span.stat', text: /Itslifestage/)
       expected following:
       <div id='taxon'>
       <div class='gallery' id='media_summary'>
       <h3 class='assistive'>Media</h3>
       <div class='images'>
       <div class='image'>
       <img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       <div class='attribution'>
       <div class='copy'>
       <p>No one has contributed any images to this page yet.</p>
       <p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       </div>
       </div>
       </div>
       </div>
       <p class='all'>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x98e70fc%20@name=TaxonOverview%5D/media">See all media</a>
       <br>
       
       </p>
       </div>
       <div class='neutral' id='iucn_status'>
       <h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       <p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       </div>
       <div class='article overview' id='text_summary'>
       <div class='header'>
       <h3>Brief summary</h3>
       </div>
       <div class='empty'>
       <p>No one has contributed a brief summary to this page yet.</p>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x98e70fc%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       </div>
       </div>
       <div class='article half list clear' id='collections_summary'>
       <div class='header'>
       <h3>Present in 0 collections</h3>
       </div>
       <div class='empty'>
       <p>
       This page isn't in any collections yet.
       <fieldset class='actions'>
       <a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       
       </fieldset>
       </p>
       </div>
       </div>
       <div class='article half list' id='communities_summary'>
       <div class='header'>
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class='empty'>
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id='sidebar'>
       <div class='article' id='data_summary'>
       <div class='header'>
       <h3>EOL has no trait data</h3>
       </div>
       <div class='empty'>
       <p>
       No one has contributed data records for Aus bus yet.
       <a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class='article' id='classification_tree'>
       <div class='header'>
       <h3>EOL has no classifications for this taxon</h3>
       </div>
       <div class='browsable classifications' id='classification_browser'>
       <li>
       Sorry, the data for this node is missing.
       </li>
       
       </div>
       </div>
       <div class='article list' id='curators_summary'>
       <div class='header'>
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class='empty'>
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class='article list updates'>
       <div class='header'>
       <h3>Latest updates</h3>
       </div>
       <div class='empty'>
       <p>No one has provided updates yet.</p>
       </div>
       
       <h4 class='assistive'>Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       <input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       <input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       <input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       <input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       <input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       <fieldset>
       <img alt="Your profile picture, if you have provided one." src="/assets/whatever" title="Your profile picture and name will appear next to your comment in listings." />
       <div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       </textarea>
       </div>
       </fieldset>
       <fieldset class='actions'>
       <input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       </fieldset>
       </form>
       
       
       </div>
       </div>
       
       to have at least 1 element matching "span.stat", found 0.
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:113:in `block (3 levels) in <top (required)>'

Progress: |================================================================================================
  37) taxa/overview/show logged with see_data permission should show sex
     Failure/Error: expect(rendered).to have_tag('span.stat', text: /Itssex/)
       expected following:
       <div id='taxon'>
       <div class='gallery' id='media_summary'>
       <h3 class='assistive'>Media</h3>
       <div class='images'>
       <div class='image'>
       <img alt="" src="/assets/v2/img_taxon-placeholder.png" />
       <div class='attribution'>
       <div class='copy'>
       <p>No one has contributed any images to this page yet.</p>
       <p><a href="/info/contribute">Learn how to contribute images to EOL.</a></p>
       </div>
       </div>
       </div>
       </div>
       <p class='all'>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9368af4%20@name=TaxonOverview%5D/media">See all media</a>
       <br>
       
       </p>
       </div>
       <div class='neutral' id='iucn_status'>
       <h3><abbr title="International Union for Conservation of Nature">IUCN</abbr> threat status:</h3>
       <p><a href="http://iucn.org" rel="nofollow" title="This link will take you to the International Union for Conservation of Nature (IUCN) Web site where you can find more information on the IUCN Red List of Threatened Species.">lucky</a></p>
       </div>
       <div class='article overview' id='text_summary'>
       <div class='header'>
       <h3>Brief summary</h3>
       </div>
       <div class='empty'>
       <p>No one has contributed a brief summary to this page yet.</p>
       <a href="/pages/%23%5BRSpec::Mocks::Mock:0x9368af4%20@name=TaxonOverview%5D/data_objects/new" class="button">Add a brief summary to this page</a>
       </div>
       </div>
       <div class='article half list clear' id='collections_summary'>
       <div class='header'>
       <h3>Present in 0 collections</h3>
       </div>
       <div class='empty'>
       <p>
       This page isn't in any collections yet.
       <fieldset class='actions'>
       <a href="http://test.host/collections/choose_collect_target?item_id=1&amp;item_type=RSpec%3A%3AMocks%3A%3AMock" class="button">Add to a collection</a>
       
       </fieldset>
       </p>
       </div>
       </div>
       <div class='article half list' id='communities_summary'>
       <div class='header'>
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class='empty'>
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id='sidebar'>
       <div class='article' id='data_summary'>
       <div class='header'>
       <h3>EOL has no trait data</h3>
       </div>
       <div class='empty'>
       <p>
       No one has contributed data records for Aus bus yet.
       <a href="http://test.host/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class='article' id='classification_tree'>
       <div class='header'>
       <h3>EOL has no classifications for this taxon</h3>
       </div>
       <div class='browsable classifications' id='classification_browser'>
       <li>
       Sorry, the data for this node is missing.
       </li>
       
       </div>
       </div>
       <div class='article list' id='curators_summary'>
       <div class='header'>
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class='empty'>
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class='article list updates'>
       <div class='header'>
       <h3>Latest updates</h3>
       </div>
       <div class='empty'>
       <p>No one has provided updates yet.</p>
       </div>
       
       <h4 class='assistive'>Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div><input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="RSpec::Mocks::Mock" />
       <input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="1" />
       <input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden" />
       <input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden" />
       <input id="return_to" name="return_to" type="hidden" value="http://yes.we/really_have/this-helper.method" />
       <input id="submit_to" name="submit_to" type="hidden" value="/comments/create" />
       <fieldset>
       <img alt="Your profile picture, if you have provided one." src="/assets/whatever" title="Your profile picture and name will appear next to your comment in listings." />
       <div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3">
       </textarea>
       </div>
       </fieldset>
       <fieldset class='actions'>
       <input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment" />
       </fieldset>
       </form>
       
       
       </div>
       </div>
       
       to have at least 1 element matching "span.stat", found 0.
     # ./spec/views/taxa/overview/show.html.haml_spec.rb:122:in `block (3 levels) in <top (required)>'

Progress: |====================================================================================================
  38) KnownUrisController GET autocomplete_known_uri_predicates should allow access to users with data privilege
     Failure/Error: expect { get :autocomplete_known_uri_predicates }.not_to raise_error
       expected no Exception, got #<NoMethodError: undefined method `uri' for nil:NilClass> with backtrace:
         # ./lib/eol/sparql/client.rb:173:in `block (3 levels) in all_measurement_type_known_uris'
         # ./lib/eol/sparql/client.rb:173:in `each'
         # ./lib/eol/sparql/client.rb:173:in `detect'
         # ./lib/eol/sparql/client.rb:173:in `block (2 levels) in all_measurement_type_known_uris'
         # ./lib/eol/sparql/client.rb:173:in `map'
         # ./lib/eol/sparql/client.rb:173:in `block in all_measurement_type_known_uris'
         # ./lib/eol/local_cacheable.rb:13:in `block (2 levels) in cache_fetch_with_local_timeout'
         # ./lib/eol/local_cacheable.rb:12:in `block in cache_fetch_with_local_timeout'
         # ./lib/eol/local_cacheable.rb:38:in `cache_locally_with_key'
         # ./lib/eol/local_cacheable.rb:11:in `cache_fetch_with_local_timeout'
         # ./lib/eol/sparql/client.rb:169:in `all_measurement_type_known_uris'
         # ./app/controllers/known_uris_controller.rb:207:in `block in autocomplete_known_uri_predicates'
         # ./app/controllers/known_uris_controller.rb:207:in `delete_if'
         # ./app/controllers/known_uris_controller.rb:207:in `autocomplete_known_uri_predicates'
         # ./spec/controllers/known_uris_controller_spec.rb:125:in `block (4 levels) in <top (required)>'
         # ./spec/controllers/known_uris_controller_spec.rb:125:in `block (3 levels) in <top (required)>'
     # ./spec/controllers/known_uris_controller_spec.rb:125:in `block (3 levels) in <top (required)>'

Progress: |========================================================================================================
  39) data_search/index with no results when server unavailable should have a warning
     Failure/Error: expect(rendered).to have_content I18n.t(:data_server_unavailable)
       expected there to be content "Data on EOL is temporarily unavailable. Please check back later. Sorry for any inconvenience." in "\n\n"
     # ./spec/views/data_search/index.html.haml_spec.rb:24:in `block (4 levels) in <top (required)>'

Progress: |========================================================================================================
  40) data_search/index with results shows a row
     Failure/Error: expect(rendered).to match(@result.object)
       expected "<div class='empty'>\n<p></p>\n</div>\n" to match "result1"
       Diff:
       @@ -1,2 +1,4 @@
       -result1
       +<div class='empty'>
       +<p></p>
       +</div>
     # ./spec/views/data_search/index.html.haml_spec.rb:47:in `block (3 levels) in <top (required)>'

Progress: |========================================================================================================
  41) data_search/index with results uses a placeholder when a row is hidden
     Failure/Error: expect(rendered).to match(I18n.t(:data_search_row_hidden))
       expected "<div class='empty'>\n<p></p>\n</div>\n" to match "A curator has hidden this row of data."
       Diff:
       @@ -1,2 +1,4 @@
       -A curator has hidden this row of data.
       +<div class='empty'>
       +<p></p>
       +</div>
     # ./spec/views/data_search/index.html.haml_spec.rb:52:in `block (3 levels) in <top (required)>'

Progress: |==============================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071617393170503765.html

  42) Taxa page literature when taxon has all expected data - taxon_concept it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Literature - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Literature\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\n\n\n\n\nOverview\nDetail\nData\n0 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\n\n\n\n\n\n\n\n\nLiterature references\n\n\nBiodiversity Heritage Library\n\n\n\n\n\nThe following bibliography has been generated by bringing together all references provided by our content partners. There may be duplication.\nReferences\n\nA published visible reference for testing.\n\n\n\nA published visible reference with a DOI identifier for testing.\n \n10.12355/foo/bar.baz.230 \n\n\n\nA published visible reference with a URL identifier for testing.\n \nsome/url.html \n\n\n\nA published visible reference with an invalid identifier for testing.\n\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nLogin or Create Account\nBecome part of the EOL community!\nJoin EOL now\n\nAlready a member?\nSign in\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:347
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |==============================================================================================================current : , super : TaxonConcept #21: 

"should use supercedure to find taxon if user visits the other concept" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071617416409452116.html

  43) Taxa page when taxon supercedes another concept should use supercedure to find taxon if user visits the other concept
     Failure/Error: current_url.should match /#{taxon_overview_path(@taxon_concept)}/
       expected "http://www.example.com/pages/21/overview" to match /\/pages\/9\/overview/
       Diff:
       @@ -1,2 +1,2 @@
       -/\/pages\/9\/overview/
       +"http://www.example.com/pages/21/overview"
     # ./spec/features/taxa_page_spec.rb:418:in `block (3 levels) in <top (required)>'

Progress: |==============================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071617492103492898.html

  44) Taxa page overview when taxon has all expected data - taxon_concept it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Overview - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Overview\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\n\n\n\n\nOverview\nDetail\nData\n14 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\n\n\n\n\n\n\n\nMedia\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx Trusted\n\n\n\n\nPublic Domain\n\n\n\nBiology of Aging\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx Trusted\n\n\n\n\nPublic Domain\n\n\n\nBiology of Aging\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx Trusted\n\n\n\n\nPublic Domain\n\n\n\nBiology of Aging\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx Trusted\n\n\n\n\nPublic Domain\n\n\n\nBiology of Aging\n\n\n\n\n\n\n\n\n\n\n\nSee all media\n\n\n\n\n\nBrief Summary\nRead full entry\n\n\nLearn more about this article\n\n\n\nThis is a test brief summary.\n\nTrusted\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\n\n\n\n\nPresent in 0 collections\n\n\n\nThis page isn't in any collections yet.\nAdd to a collection\n\n\n\n\n\nBelongs to 0 communities\n\n\nThis taxon hasn't been featured in any communities yet.\nLearn more about Communities\n\n\n\n\n\n\nEOL has no trait data\n\n\n\nNo one has contributed data records for Fugais utharumatvctsty A. Ankundinx yet.\nLearn how to contribute.\n\n\n\n\n\n\nFound in 4 classifications\nSee all 4 approved classifications in which this taxon appears.\n\n\nSpecies recognized by Catalogue of Life:\n\n\nFugais utharumatvctsty A. Ankundinx\n\n\n\n\n\n\nReviewed by 0 curators\nLearn how to curate\n\n\nOur curators haven't taken any action on this page yet.\n\n\n\n\nLatest updates\nSee all 31 updates for this page.\n\n\n\n\n\n\nDorv Luettgfe commented on \"Fugais utharumatvctsty A. Ankundinx\":\n\n\nTest comment by a logged in user. unique462string\n\n\nless than a minute ago\n\nReply\n\n\n\n\n\n\n\n\n\nDorv Luettgfe commented on \"Fugais utharumatvctsty A. Ankundinx\":\n\n\nTest comment by a logged in user unique461string.\n\n\nless than a minute ago\n\nReply\n\n\n\n\n\n\n\n\nJoshubc Tpp curated \"Image of Fugais utharumatvctsty A. Ankundinx\".\n\n\n\n5 days ago\n\nReply\n\n\n\n\n\n\nComo Botsforu curated \"Image of Fugais utharumatvctsty A. Ankundinx\".\n\n\n\n5 days ago\n\nReply\n\n\n\n\n\n\n\nIUCN Steif commented on \"\":\n\n\nComment on superceded taxon.\n\n\n2 minutes ago\n\nReply\n\n\n\n\nAdd a new comment\n\nYour comment\n\n\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nLogin or Create Account\nBecome part of the EOL community!\nJoin EOL now\n\nAlready a member?\nSign in\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:239
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |==============================================================================================================
"should show IUCN Red List status" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071617586261924304.html

  45) Taxa page overview when taxon has all expected data - taxon_concept it should behave like taxon overview tab should show IUCN Red List status
     Failure/Error: expect(page).to have_tag('div#iucn_status a')
       expected following:
       <!DOCTYPE html>
       <html lang="en" xml:lang="en" xmlns:fb="http://ogp.me/ns/fb#" xmlns:og="http://ogp.me/ns#" xmlns="http://www.w3.org/1999/xhtml">
       <head>
       <title>Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Overview - Encyclopedia of Life</title>
       <meta charset="utf-8">
       <meta content="text/html; charset=utf-8" http-equiv="Content-type">
       <meta content="Cromulent Quiiurealiatsty, Fugais utharumatvctsty A. Ankundinx, Cromulent Quiiurealiatsty Overview, Fugais utharumatvctsty A. Ankundinx Overview" name="keywords">
       <meta content="true" name="MSSmartTagsPreventParsing">
       <meta content="EOL V2 Beta" name="app_version">
       <meta content="http://www.example.com/pages/9/overview" property="og:url">
       <meta content="Encyclopedia of Life" property="og:site_name">
       <meta content="website" property="og:type">
       <meta content="Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Overview - Encyclopedia of Life" property="og:title">
       <meta content="localhostcontent/2012/03/27/01/78402_260_190.jpg" property="og:image">
       <link href="http://www.example.com/pages/9/overview" rel="canonical">
       <link href="/assets/favicon.ico" rel="shortcut icon" type="image/vnd.microsoft.icon">
       <link href="/opensearchdescription.xml" rel="search" title="Encyclopedia of Life" type="application/opensearchdescription+xml">
       <link href="/assets/application_pack.css" media="all" rel="stylesheet" type="text/css">
       <!--[if IE 7]>
       <link href="/assets/ie7.css" media="all" rel="stylesheet" type="text/css" />
       <![endif]--><script src="/assets/application.js" type="text/javascript"></script>
       </head>
       <body>
       <div id="central">
       <div class="section" role="main">
       <!-- ======================== -->
       
       <div class="with_nav" id="page_heading">
       <div class="site_column">
       <div class="hgroup">
       <h1 class="scientific_name">
       Fugais utharumatvctsty A. Ankundinx
       <span class="assistive"> &amp;mdash; Overview</span>
       </h1>
       <h2 title="Preferred common name for this taxon.">
       Cromulent Quiiurealiatsty
       <small><a href="/pages/9/names">learn more about names for this taxon</a></small>
       </h2>
       
       
       </div>
       <div class="page_actions">
       <ul>
       <li>
       <a href="http://www.example.com/collections/choose_collect_target?item_id=9&amp;item_type=TaxonConcept" class="button">Add to a collection</a>
       
       </li>
       <!-- - if @taxon_data && @taxon_data.downloadable? -->
       <!-- %li -->
       <!-- = link_to I18n.t(:download_data), taxon_overview_path(@taxon_page), :class => 'button', :onclick => 'return false' -->
       </ul>
       </div>
       
       <ul class="nav">
       <li class="active"><a href="/pages/9/overview">Overview</a></li>
       <li><a href="/pages/9/details">Detail</a></li>
       <li><a href="/pages/9/data">Data</a></li>
       <li><a href="/pages/9/media">14 Media</a></li>
       <li><a href="/pages/9/maps">0 Maps</a></li>
       <li><a href="/pages/9/names">Names</a></li>
       <li><a href="/pages/9/communities">Community</a></li>
       <li><a href="/pages/9/resources">Resources</a></li>
       <li><a href="/pages/9/literature">Literature</a></li>
       <li><a href="/pages/9/updates">Updates</a></li>
       <li>
       </ul>
       </div>
       </div>
       <div id="content">
       <div class="site_column">
       <div id="taxon">
       <div class="gallery" id="media_summary">
       <h3 class="assistive">Media</h3>
       <div class="images">
       <div class="image" style="opacity:1; z-index: 1;">
       <a href="/data_objects/6">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="6" data-thumb="localhostcontent/2012/03/27/01/78402_98_68.jpg" src="localhostcontent/2012/03/27/01/78402_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/4">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="4" data-thumb="localhostcontent/2011/12/22/01/71145_98_68.jpg" src="localhostcontent/2011/12/22/01/71145_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/8">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="8" data-thumb="localhostcontent/2011/11/02/02/99829_98_68.jpg" src="localhostcontent/2011/11/02/02/99829_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/9">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="9" data-thumb="localhostcontent/2013/02/04/10/61045_98_68.jpg" src="localhostcontent/2013/02/04/10/61045_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       </div>
       <p class="all">
       <a href="/pages/9/media">See all media</a>
       <br></p>
       </div>
       <div class="article overview" id="text_summary">
       <div class="trusted" data-text-id="19">
       <div class="header">
       <h3>Brief Summary</h3>
       <a href="/pages/9/details">Read full entry</a>
       </div>
       <div class="meta learn_more">
       <p><a href="/data_objects/19">Learn more about this article</a></p>
       
       </div>
       <div class="copy">
       This is a test brief summary.
       </div>
       <p class="flag trusted">Trusted</p>
       <div class="meta attribution">
       <a href="http://creativecommons.org/licenses/by/3.0/" rel="nofollow"><img alt="Creative Commons Attribution 3.0 (CC BY 3.0)" src="/assets/licenses/cc_by_small.png"></a>
       
       <div class="copy">
       <p class="owner">
       © Someone
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="article half list clear" id="collections_summary">
       <div class="header">
       <h3>Present in 0 collections</h3>
       </div>
       <div class="empty">
       <p>
       This page isn't in any collections yet.
       </p>
       <fieldset class="actions">
       <a href="http://www.example.com/collections/choose_collect_target?item_id=9&amp;item_type=TaxonConcept" class="button">Add to a collection</a>
       
       </fieldset>
       </div>
       </div>
       <div class="article half list" id="communities_summary">
       <div class="header">
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class="empty">
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id="sidebar">
       <div class="article" id="data_summary">
       <div class="header">
       <h3>EOL has no trait data</h3>
       </div>
       <div class="empty">
       <p>
       No one has contributed data records for Fugais utharumatvctsty A. Ankundinx yet.
       <a href="http://www.example.com/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class="article" id="classification_tree">
       <div class="header">
       <h3>Found in 4 classifications</h3>
       <a href="/pages/9/names">See all <span class="assistive">4 approved classifications in which this taxon appears.</span></a>
       </div>
       <div class="browsable classifications" id="classification_browser">
       <h4>
       <b>Species</b> recognized by <a href="/content_partners/2">Catalogue of Life</a>:</h4>
       <ul class="branch">
       <li>
       <span class="current">
       Fugais utharumatvctsty A. Ankundinx
       </span>
       </li>
       </ul>
       </div>
       </div>
       <div class="article list" id="curators_summary">
       <div class="header">
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class="empty">
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       <div class="article list updates">
       <div class="header">
       <h3>Latest updates</h3>
       <a href="/pages/9/updates">See all <span class="assistive">31 updates for this page.</span></a>
       </div>
       <ul class="feed">
       <li id="Comment-31">
       <div class="editable">
       <a href="http://www.example.com/users/14" class="avatar"><img alt="Profile picture of Dorv Luettgfe who took this action." src="/assets/localhostcontent/2011/12/09/00/37380_88_88.jpg"></a>
       <div class="details">
       <p>
       <strong><a href="http://www.example.com/users/14">Dorv Luettgfe</a></strong> commented on "<a href="http://www.example.com/pages/9">Fugais utharumatvctsty A. Ankundinx</a>":
       </p>
       <blockquote cite="Dorv Luettgfe">
       Test comment by a logged in user. unique462string
       </blockquote>
       <p class="meta">
       less than a minute ago
       </p>
       <ul class="actions">
       <li class="reply"><a href="http://www.example.com/pages/9#reply-to-Comment-31" data-reply-to-id="31" data-reply-to-type="Comment" data-reply-to="Dorv Luettgfe">Reply</a></li>
       </ul>
       </div>
       
       </div>
       </li>
       <li id="Comment-30">
       <div class="editable">
       <a href="http://www.example.com/users/14" class="avatar"><img alt="Profile picture of Dorv Luettgfe who took this action." src="/assets/localhostcontent/2011/12/09/00/37380_88_88.jpg"></a>
       <div class="details">
       <p>
       <strong><a href="http://www.example.com/users/14">Dorv Luettgfe</a></strong> commented on "<a href="http://www.example.com/pages/9">Fugais utharumatvctsty A. Ankundinx</a>":
       </p>
       <blockquote cite="Dorv Luettgfe">
       Test comment by a logged in user unique461string.
       </blockquote>
       <p class="meta">
       1 minute ago
       </p>
       <ul class="actions">
       <li class="reply"><a href="http://www.example.com/pages/9#reply-to-Comment-30" data-reply-to-id="30" data-reply-to-type="Comment" data-reply-to="Dorv Luettgfe">Reply</a></li>
       </ul>
       </div>
       
       </div>
       </li>
       <li id="CuratorActivityLog-2">
       <a href="http://www.example.com/users/8" class="avatar"><img alt="Profile picture of Joshubc Tpp who took this action." height="48" src="/assets/localhostcontent/2012/12/28/23/65133_88_88.jpg" width="48"></a>
       <div class="details">
       <p>
       <strong><a href="http://www.example.com/users/8">Joshubc Tpp</a></strong> curated "<a href="http://www.example.com/data_objects/8">Image of Fugais utharumatvctsty A. Ankundinx</a>".
       </p>
       
       <p class="meta">
       5 days ago
       </p>
       <ul class="actions">
       <li class="reply"><a href="http://www.example.com/pages/8#reply-to-CuratorActivityLog-2" data-reply-to-id="2" data-reply-to-type="CuratorActivityLog" data-reply-to="Joshubc Tpp">Reply</a></li>
       </ul>
       </div>
       </li>
       <li id="CuratorActivityLog-3">
       <a href="http://www.example.com/users/10" class="avatar"><img alt="Profile picture of Como Botsforu who took this action." height="48" src="/assets/localhostcontent/2011/11/02/06/80528_88_88.jpg" width="48"></a>
       <div class="details">
       <p>
       <strong><a href="http://www.example.com/users/10">Como Botsforu</a></strong> curated "<a href="http://www.example.com/data_objects/9">Image of Fugais utharumatvctsty A. Ankundinx</a>".
       </p>
       
       <p class="meta">
       5 days ago
       </p>
       <ul class="actions">
       <li class="reply"><a href="http://www.example.com/pages/9#reply-to-CuratorActivityLog-3" data-reply-to-id="3" data-reply-to-type="CuratorActivityLog" data-reply-to="Como Botsforu">Reply</a></li>
       </ul>
       </div>
       </li>
       <li id="Comment-23">
       <div class="editable">
       <a href="http://www.example.com/users/1" class="avatar"><img alt="Profile picture of IUCN Steif who took this action." src="/assets/localhostcontent/2012/11/04/08/27144_88_88.jpg"></a>
       <div class="details">
       <p>
       <strong><a href="http://www.example.com/users/1">IUCN Steif</a></strong> commented on "<a href="http://www.example.com/pages/21"></a>":
       </p>
       <blockquote cite="IUCN Steif">
       Comment on superceded taxon.
       </blockquote>
       <p class="meta">
       2 minutes ago
       </p>
       <ul class="actions">
       <li class="reply"><a href="http://www.example.com/pages/21#reply-to-Comment-23" data-reply-to-id="23" data-reply-to-type="Comment" data-reply-to="IUCN Steif">Reply</a></li>
       </ul>
       </div>
       
       </div>
       </li>
       </ul>
       <h4 class="assistive">Add a new comment</h4>
       <form accept-charset="UTF-8" action="/comments.html" class="comment" id="new_comment" method="post">
       <div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="✓"></div>
       <input id="comment_parent_type" name="comment[parent_type]" type="hidden" value="TaxonConcept"><input id="comment_parent_id" name="comment[parent_id]" type="hidden" value="9"><input id="comment_reply_to_type" name="comment[reply_to_type]" type="hidden"><input id="comment_reply_to_id" name="comment[reply_to_id]" type="hidden"><input id="return_to" name="return_to" type="hidden" value="http://www.example.com/pages/9/overview"><input id="submit_to" name="submit_to" type="hidden" value="/comments/create"><fieldset>
       <img alt="" src="/assets/v2/logos/user_default.png"><div>
       <label class="assistive" for="comment_body">Your comment</label>
       <textarea cols="60" id="comment_body" name="comment[body]" rows="3"></textarea>
       </div>
       </fieldset>
       <fieldset class="actions"><input data-cancel="Cancel" data-reply="Leave Reply" name="commit" type="submit" value="Post Comment"></fieldset>
       </form>
       
       
       </div>
       </div>
       
       <div class="disclaimer copy">
       <h3 class="assistive">Disclaimer</h3>
       <p>EOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.</p>
       <p>To request an improvement, please leave a comment on the page. Thank you!</p>
       </div>
       </div>
       </div>
       
       <!-- ======================== -->
       </div>
       </div>
       <div id="banner">
       <div class="site_column">
       <p><strong>Introducing <a href="/traitbank">TraitBank</a>:</strong> search millions of data records on EOL   <small>•</small>   <a href="/traitbank">Learn more</a>   <small>•</small>   <a href="/data_search">Search data</a></p>
       </div>
       </div>
       <div id="header">
       <div class="section">
       <h1><a href="http://www.example.com/" title="This link will take you to the home page of the Encyclopedia of Life Web site">Encyclopedia of Life</a></h1>
       <div class="global_navigation" role="navigation">
       <h2 class="assistive">Global Navigation</h2>
       <ul class="nav">
       <li>
       <a href="/discover">Education</a>
       </li>
       <li>
       <a href="/help">Help</a>
       </li>
       <li>
       <a href="/about">What is EOL?</a>
       </li>
       <li>
       <a href="/news">EOL News</a>
       </li>
       </ul>
       </div>
       
       <div class="actions">
       <div class="language">
       <p class="en" title="This is the currently selected language.">
       <a href="/language"><span>
       English
       </span>
       </a></p>
       <ul>
       <li class="en">
       <a href="http://www.example.com/set_language?language=en&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Foverview" title="Switch the site language to English">English</a>
       </li>
       <li class="fr">
       <a href="http://www.example.com/set_language?language=fr&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Foverview" title="Switch the site language to Français">Français</a>
       </li>
       <li class="es">
       <a href="http://www.example.com/set_language?language=es&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Foverview" title="Switch the site language to Español">Español</a>
       </li>
       <li class="ar">
       <a href="http://www.example.com/set_language?language=ar&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Foverview" title="Switch the site language to العربية">العربية</a>
       </li>
       </ul>
       </div>
       </div>
       <form action="http://www.example.com/search?q=" id="simple_search" method="get" role="search">
       <h2 class="assistive">Search the site</h2>
       <fieldset>
       <label class="assistive" for="autocomplete_q">Search EOL</label>
       <div class="text">
       <input data-autocomplete="/search/autocomplete_taxon" data-include-site_search="form#simple_search" data-min-length="3" id="autocomplete_q" maxlength="250" name="q" placeholder="Search EOL ..." size="250" title="Enter a common name or a scientific name of a living creature you would like to know more about. You can also search for EOL members, collections and communities." type="text">
       </div>
       <input data_error="You must enter a search term." data_unchanged="Search EOL ..." name="search" type="submit" value="Go">
       </fieldset>
       </form>
       
       <div class="session join">
       <h3 class="assistive">Login or Create Account</h3>
       <p>Become part of the <abbr title="Encyclopedia of Life">EOL</abbr> community!</p>
       <p><a href="/users/register">Join <abbr title="Encyclopedia of Life">EOL</abbr> now</a></p>
       <p>
       Already a member?
       <a href="/login?return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Foverview">Sign in</a>
       </p>
       </div>
       
       </div>
       </div>
       <div id="footer" role="contentinfo">
       <div class="section">
       <h2 class="assistive">Site information</h2>
       <div class="wrapper">
       <div class="about">
       <h6>About EOL</h6>
       <ul>
       <li><a href="/about">What is EOL?</a></li>
       <li><a href="/traitbank">What is TraitBank?</a></li>
       <li><a href="http://blog.eol.org">The EOL Blog</a></li>
       <li><a href="/discover">Education</a></li>
       <li><a href="/statistics">Statistics</a></li>
       <li><a href="/info/glossary">Glossary</a></li>
       <li><a href="http://podcast.eol.org/podcast">Podcasts</a></li>
       <li><a href="/info/citing">Citing EOL</a></li>
       <li><a href="/help">Help</a></li>
       <li><a href="/terms_of_use">Terms of Use</a></li>
       <li><a href="/contact_us">Contact Us</a></li>
       </ul>
       </div>
       <div class="learn_more">
       <h6>Learn more about</h6>
       <ul>
       <li>
       <ul>
       <li><a href="/info/animals">Animals</a></li>
       <li><a href="/info/mammals">Mammals</a></li>
       <li><a href="/info/birds">Birds</a></li>
       <li><a href="/info/amphibians">Amphibians</a></li>
       <li><a href="/info/reptiles">Reptiles</a></li>
       <li><a href="/info/fishes">Fishes</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/invertebrates">Invertebrates</a></li>
       <li><a href="/info/crustaceans">Crustaceans</a></li>
       <li><a href="/info/mollusks">Mollusks</a></li>
       <li><a href="/info/insects">Insects</a></li>
       <li><a href="/info/spiders">Spiders</a></li>
       <li><a href="/info/worms">Worms</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/plants">Plants</a></li>
       <li><a href="/info/flowering_plants">Flowering Plants</a></li>
       <li><a href="/info/trees">Trees</a></li>
       </ul>
       <ul>
       <li><a href="/info/fungi">Fungi</a></li>
       <li><a href="/info/mushrooms">Mushrooms</a></li>
       <li><a href="/info/molds">Molds</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/bacteria">Bacteria</a></li>
       </ul>
       <ul>
       <li><a href="/info/algae">Algae</a></li>
       </ul>
       <ul>
       <li><a href="/info/protists">Protists</a></li>
       </ul>
       <ul>
       <li><a href="/info/archaea">Archaea</a></li>
       </ul>
       <ul>
       <li><a href="/info/viruses">Viruses</a></li>
       </ul>
       </li>
       </ul>
       <div class="partners">
       <h6><a href="http://www.biodiversitylibrary.org/">Biodiversity Heritage Library</a></h6>
       <p>Visit the Biodiversity Heritage Library</p>
       </div>
       <ul class="social_media">
       <li><a href="http://twitter.com/#!/EOL" class="twitter" rel="nofollow">Twitter</a></li>
       <li><a href="http://www.facebook.com/encyclopediaoflife" class="facebook" rel="nofollow">Facebook</a></li>
       <li><a href="http://www.flickr.com/groups/encyclopedia_of_life/" class="flickr" rel="nofollow">Flickr</a></li>
       <li><a href="http://www.youtube.com/user/EncyclopediaOfLife/" class="youtube" rel="nofollow">YouTube</a></li>
       <li><a href="http://pinterest.com/eoflife/" class="pinterest" rel="nofollow">Pinterest</a></li>
       <li><a href="http://vimeo.com/groups/encyclopediaoflife" class="vimeo" rel="nofollow">Vimeo</a></li>
       <li><a href="//plus.google.com/+encyclopediaoflife?prsrc=3" class="google_plus" rel="publisher"><img alt="&lt;span class=" translation_missing title="translation missing: en.layouts.footer.google_plus">Google Plus" src="//ssl.gstatic.com/images/icons/gplus-32.png" /&gt;</a></li>
       </ul>
       </div>
       <div class="questions">
       <h6>Tell me more</h6>
       <ul>
       <li><a href="/info/about_biodiversity">What is biodiversity?</a></li>
       <li><a href="/info/species_concepts">What is a species?</a></li>
       <li><a href="/info/discovering_diversity">How are species discovered?</a></li>
       <li><a href="/info/naming_species">How are species named?</a></li>
       <li><a href="/info/taxonomy_phylogenetics">What is a biological classification?</a></li>
       <li><a href="/info/invasive_species">What is an invasive species?</a></li>
       <li><a href="/info/indicator_species">What is an indicator species?</a></li>
       <li><a href="/info/model_organism">What is a model organism?</a></li>
       <li><a href="/info/contribute_research">How can I contribute to research?</a></li>
       <li><a href="/info/evolution">What is evolution?</a></li>
       </ul>
       </div>
       </div>
       </div>
       
       
       </div>
       <script src="/assets/head.load.min.js" type="text/javascript"></script>
       </body>
       </html>
       
       to have at least 1 element matching "div#iucn_status a", found 0.
     Shared Example Group: "taxon overview tab" called from ./spec/features/taxa_page_spec.rb:242
     # ./spec/features/taxa_page_spec.rb:101:in `block (3 levels) in <top (required)>'

Progress: |===============================================================================================================
"should show IUCN Red List status" failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071618242540979271.html

  46) Taxa page overview when taxon has all expected data - hierarchy_entry it should behave like taxon overview tab should show IUCN Red List status
     Failure/Error: expect(page).to have_tag('div#iucn_status a')
       expected following:
       <!DOCTYPE html>
       <html lang="en" xml:lang="en" xmlns:fb="http://ogp.me/ns/fb#" xmlns:og="http://ogp.me/ns#" xmlns="http://www.w3.org/1999/xhtml">
       <head>
       <title>Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Species 2000 &amp; ITIS Catalogue of Life: May 2012 - Overview - Encyclopedia of Life</title>
       <meta charset="utf-8">
       <meta content="text/html; charset=utf-8" http-equiv="Content-type">
       <meta content="Cromulent Quiiurealiatsty, Fugais utharumatvctsty A. Ankundinx, Cromulent Quiiurealiatsty Overview, Fugais utharumatvctsty A. Ankundinx Overview, Species 2000 &amp; ITIS Catalogue of Life: May 2012" name="keywords">
       <meta content="true" name="MSSmartTagsPreventParsing">
       <meta content="EOL V2 Beta" name="app_version">
       <meta content="http://www.example.com/pages/9/hierarchy_entries/4/overview" property="og:url">
       <meta content="Encyclopedia of Life" property="og:site_name">
       <meta content="website" property="og:type">
       <meta content="Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Species 2000 &amp; ITIS Catalogue of Life: May 2012 - Overview - Encyclopedia of Life" property="og:title">
       <meta content="localhostcontent/2012/03/27/01/78402_260_190.jpg" property="og:image">
       <link href="http://www.example.com/pages/9/hierarchy_entries/4/overview" rel="canonical">
       <link href="/assets/favicon.ico" rel="shortcut icon" type="image/vnd.microsoft.icon">
       <link href="/opensearchdescription.xml" rel="search" title="Encyclopedia of Life" type="application/opensearchdescription+xml">
       <link href="/assets/application_pack.css" media="all" rel="stylesheet" type="text/css">
       <!--[if IE 7]>
       <link href="/assets/ie7.css" media="all" rel="stylesheet" type="text/css" />
       <![endif]--><script src="/assets/application.js" type="text/javascript"></script>
       </head>
       <body>
       <div id="central">
       <div class="section" role="main">
       <!-- ======================== -->
       <form accept-charset="UTF-8" action="/pages/9/hierarchy_entries/4/switch" class="select_content_partner select_submit" id="switch_hierarchy_entry" method="post">
       <div style="margin:0;padding:0;display:inline">
       <input name="utf8" type="hidden" value="✓"><input name="_method" type="hidden" value="put">
       </div>
       <fieldset>
       <p>You are viewing this Species as classified by:</p>
       <select id="hierarchy_entry_id" name="hierarchy_entry[id]"><option value="4" selected>Species 2000 &amp; ITIS Catalogue of Life: May 2012</option>
       <option value="5">Species 2000 &amp; ITIS Catalogue of Life: May 2012</option>
       <option value="19">Species 2000 &amp; ITIS Catalogue of Life: May 2012</option></select>
       </fieldset>
       <fieldset class="actions"><input type="submit" value="Submit"></fieldset>
       </form>
       
       
       <div class="with_nav" id="page_heading">
       <div class="site_column">
       <div class="hgroup">
       <h1 class="scientific_name">
       Fugais utharumatvctsty A. Ankundinx
       <span class="assistive"> &amp;mdash; Overview</span>
       </h1>
       <h2 title="Preferred common name for this taxon.">
       Cromulent Quiiurealiatsty
       <small><a href="/pages/9/hierarchy_entries/4/names">learn more about names for this taxon</a></small>
       </h2>
       
       
       </div>
       <div class="page_actions">
       <ul>
       <li>
       <a href="http://www.example.com/collections/choose_collect_target?item_id=9&amp;item_type=TaxonConcept" class="button">Add to a collection</a>
       
       </li>
       <!-- - if @taxon_data && @taxon_data.downloadable? -->
       <!-- %li -->
       <!-- = link_to I18n.t(:download_data), taxon_overview_path(@taxon_page), :class => 'button', :onclick => 'return false' -->
       </ul>
       </div>
       
       <p class="status" id="citation">
       Species recognized by <a href="/content_partners/2">Catalogue of Life</a>
        • 
       <a href="/pages/9/overview">Remove classification filter</a>
       </p>
       <ul class="nav">
       <li class="active"><a href="/pages/9/hierarchy_entries/4/overview">Overview</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/details">Detail</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/data">Data</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/media">14 Media</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/maps">0 Maps</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/names">Names</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/communities">Community</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/resources">Resources</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/literature">Literature</a></li>
       <li><a href="/pages/9/hierarchy_entries/4/updates">Updates</a></li>
       <li>
       </ul>
       </div>
       </div>
       <div id="content">
       <div class="site_column">
       <div id="taxon">
       <div class="gallery" id="media_summary">
       <h3 class="assistive">Media</h3>
       <div class="images">
       <div class="image" style="opacity:1; z-index: 1;">
       <a href="/data_objects/6">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="6" data-thumb="localhostcontent/2012/03/27/01/78402_98_68.jpg" src="localhostcontent/2012/03/27/01/78402_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/4">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="4" data-thumb="localhostcontent/2011/12/22/01/71145_98_68.jpg" src="localhostcontent/2011/12/22/01/71145_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/8">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="8" data-thumb="localhostcontent/2011/11/02/02/99829_98_68.jpg" src="localhostcontent/2011/11/02/02/99829_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="image" style="opacity:0; z-index: -1;">
       <a href="/data_objects/9">
       <img alt="Image of Fugais utharumatvctsty A. Ankundinx" data-data-object-id="9" data-thumb="localhostcontent/2013/02/04/10/61045_98_68.jpg" src="localhostcontent/2013/02/04/10/61045_580_360.jpg"></a>
       <div class="details">
       <div class="copy">
       <p>
       <a href="/pages/9/overview">Fugais utharumatvctsty A. Ankundinx</a> <span class="flag trusted">Trusted</span>
       </p>
       
       </div>
       <div class="attribution">
       <span class="license">Public Domain</span>
       
       <div class="copy">
       <p class="owner">
       Biology of Aging
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       </div>
       <p class="all">
       <a href="/pages/9/hierarchy_entries/4/media">See all media</a>
       <br></p>
       </div>
       <div class="article overview" id="text_summary">
       <div class="trusted" data-text-id="19">
       <div class="header">
       <h3>Brief Summary</h3>
       <a href="/pages/9/hierarchy_entries/4/details">Read full entry</a>
       </div>
       <div class="meta learn_more">
       <p><a href="/data_objects/19">Learn more about this article</a></p>
       
       </div>
       <div class="copy">
       This is a test brief summary.
       </div>
       <p class="flag trusted">Trusted</p>
       <div class="meta attribution">
       <a href="http://creativecommons.org/licenses/by/3.0/" rel="nofollow"><img alt="Creative Commons Attribution 3.0 (CC BY 3.0)" src="/assets/licenses/cc_by_small.png"></a>
       
       <div class="copy">
       <p class="owner">
       © Someone
       </p>
       <p>
       </p>
       
       </div>
       
       </div>
       </div>
       </div>
       <div class="article half list clear" id="collections_summary">
       <div class="header">
       <h3>Present in 0 collections</h3>
       </div>
       <div class="empty">
       <p>
       This page isn't in any collections yet.
       </p>
       <fieldset class="actions">
       <a href="http://www.example.com/collections/choose_collect_target?item_id=9&amp;item_type=TaxonConcept" class="button">Add to a collection</a>
       
       </fieldset>
       </div>
       </div>
       <div class="article half list" id="communities_summary">
       <div class="header">
       <h3>Belongs to 0 communities</h3>
       </div>
       <div class="empty">
       <p>This taxon hasn't been featured in any communities yet.</p>
       <p><a href="/info/communities">Learn more about Communities</a></p>
       </div>
       </div>
       </div>
       <div id="sidebar">
       <div class="article" id="data_summary">
       <div class="header">
       <h3>EOL has no trait data</h3>
       </div>
       <div class="empty">
       <p>
       No one has contributed data records for Fugais utharumatvctsty A. Ankundinx yet.
       <a href="http://www.example.com/info/contribute#data">Learn how to contribute.</a>
       </p>
       </div>
       </div>
       
       <div class="article" id="classification_tree">
       <div class="header">
       <h3>Classification</h3>
       <a href="/pages/9/hierarchy_entries/4/names">See all <span class="assistive">3 approved classifications in which this taxon appears.</span></a>
       </div>
       <div class="browsable classifications" id="classification_browser">
       <ul>
       <li>
       <a href="/pages/13/hierarchy_entries/10/overview">"Good title" Padderson</a> </li>
       <li>
       <a href="/pages/30/hierarchy_entries/27/overview">Adaliasii iurek L.</a> </li>
       <li>
       <a href="/pages/29/hierarchy_entries/26/overview">Animiens atdoloribuserox R. Cartwright</a> </li>
       <li>
       <a href="/pages/16/hierarchy_entries/14/overview">Autaliquideri minimajc M. Mayer</a> </li>
       <li>
       <a href="/pages/17/hierarchy_entries/15/overview">Autema officiaalivc</a> </li>
       <li>
       <a href="/pages/1/hierarchy_entries/1/overview">Beataeelia etnemoiam</a> </li>
       <li>
       <a href="/pages/14/hierarchy_entries/11/overview">Culpaensis sapienteess Linnaeus</a> </li>
       <ul class="branch"><li>
       <a href="/pages/8/hierarchy_entries/3/overview">Dignissimosii inutfc L.</a> <ul class="branch">
       <li>
       <span class="current">
       Fugais utharumatvctsty A. Ankundinx
       </span>
       </li>
       </ul>
       </li></ul>
       <li>
       <a href="/pages/28/hierarchy_entries/25/overview">Essees eaqueatk Linn</a> </li>
       <li>
       <a href="/pages/9/hierarchy_entries/5/overview">Fugais utharumatvctsty A. Ankundinx</a> </li>
       <li>
       <a href="/pages/23/hierarchy_entries/20/overview">Ipsamalius distinctioerph Linn.</a> </li>
       <li>
       <a href="/pages/910093/hierarchy_entries/2/overview">Nihileri voluptasvc Posford &amp; Ram</a> </li>
       <li>
       <a href="/pages/9/hierarchy_entries/19/overview">Some unused name</a> </li>
       <li>
       <a href="/pages/15/hierarchy_entries/13/overview">Utomnisesi sequialjc L.</a> </li>
       </ul>
       </div>
       </div>
       
       <div class="article list" id="curators_summary">
       <div class="header">
       <h3>Reviewed by 0 curators</h3>
       <a href="/curators">Learn how to curate</a>
       </div>
       <div class="empty">
       <p>Our curators haven't taken any action on this page yet.</p>
       </div>
       </div>
       </div>
       
       <div class="disclaimer copy">
       <h3 class="assistive">Disclaimer</h3>
       <p>EOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.</p>
       <p>To request an improvement, please leave a comment on the page. Thank you!</p>
       </div>
       </div>
       </div>
       
       <!-- ======================== -->
       </div>
       </div>
       <div id="banner">
       <div class="site_column">
       <p><strong>Introducing <a href="/traitbank">TraitBank</a>:</strong> search millions of data records on EOL   <small>•</small>   <a href="/traitbank">Learn more</a>   <small>•</small>   <a href="/data_search">Search data</a></p>
       </div>
       </div>
       <div id="header">
       <div class="section">
       <h1><a href="http://www.example.com/" title="This link will take you to the home page of the Encyclopedia of Life Web site">Encyclopedia of Life</a></h1>
       <div class="global_navigation" role="navigation">
       <h2 class="assistive">Global Navigation</h2>
       <ul class="nav">
       <li>
       <a href="/discover">Education</a>
       </li>
       <li>
       <a href="/help">Help</a>
       </li>
       <li>
       <a href="/about">What is EOL?</a>
       </li>
       <li>
       <a href="/news">EOL News</a>
       </li>
       </ul>
       </div>
       
       <div class="actions">
       <div class="language">
       <p class="en" title="This is the currently selected language.">
       <a href="/language"><span>
       English
       </span>
       </a></p>
       <ul>
       <li class="en">
       <a href="http://www.example.com/set_language?language=en&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Fhierarchy_entries%2F4%2Foverview" title="Switch the site language to English">English</a>
       </li>
       <li class="fr">
       <a href="http://www.example.com/set_language?language=fr&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Fhierarchy_entries%2F4%2Foverview" title="Switch the site language to Français">Français</a>
       </li>
       <li class="es">
       <a href="http://www.example.com/set_language?language=es&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Fhierarchy_entries%2F4%2Foverview" title="Switch the site language to Español">Español</a>
       </li>
       <li class="ar">
       <a href="http://www.example.com/set_language?language=ar&amp;return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Fhierarchy_entries%2F4%2Foverview" title="Switch the site language to العربية">العربية</a>
       </li>
       </ul>
       </div>
       </div>
       <form action="http://www.example.com/search?q=" id="simple_search" method="get" role="search">
       <h2 class="assistive">Search the site</h2>
       <fieldset>
       <label class="assistive" for="autocomplete_q">Search EOL</label>
       <div class="text">
       <input data-autocomplete="/search/autocomplete_taxon" data-include-site_search="form#simple_search" data-min-length="3" id="autocomplete_q" maxlength="250" name="q" placeholder="Search EOL ..." size="250" title="Enter a common name or a scientific name of a living creature you would like to know more about. You can also search for EOL members, collections and communities." type="text">
       </div>
       <input data_error="You must enter a search term." data_unchanged="Search EOL ..." name="search" type="submit" value="Go">
       </fieldset>
       </form>
       
       <div class="session join">
       <h3 class="assistive">Login or Create Account</h3>
       <p>Become part of the <abbr title="Encyclopedia of Life">EOL</abbr> community!</p>
       <p><a href="/users/register">Join <abbr title="Encyclopedia of Life">EOL</abbr> now</a></p>
       <p>
       Already a member?
       <a href="/login?return_to=http%3A%2F%2Fwww.example.com%2Fpages%2F9%2Fhierarchy_entries%2F4%2Foverview">Sign in</a>
       </p>
       </div>
       
       </div>
       </div>
       <div id="footer" role="contentinfo">
       <div class="section">
       <h2 class="assistive">Site information</h2>
       <div class="wrapper">
       <div class="about">
       <h6>About EOL</h6>
       <ul>
       <li><a href="/about">What is EOL?</a></li>
       <li><a href="/traitbank">What is TraitBank?</a></li>
       <li><a href="http://blog.eol.org">The EOL Blog</a></li>
       <li><a href="/discover">Education</a></li>
       <li><a href="/statistics">Statistics</a></li>
       <li><a href="/info/glossary">Glossary</a></li>
       <li><a href="http://podcast.eol.org/podcast">Podcasts</a></li>
       <li><a href="/info/citing">Citing EOL</a></li>
       <li><a href="/help">Help</a></li>
       <li><a href="/terms_of_use">Terms of Use</a></li>
       <li><a href="/contact_us">Contact Us</a></li>
       </ul>
       </div>
       <div class="learn_more">
       <h6>Learn more about</h6>
       <ul>
       <li>
       <ul>
       <li><a href="/info/animals">Animals</a></li>
       <li><a href="/info/mammals">Mammals</a></li>
       <li><a href="/info/birds">Birds</a></li>
       <li><a href="/info/amphibians">Amphibians</a></li>
       <li><a href="/info/reptiles">Reptiles</a></li>
       <li><a href="/info/fishes">Fishes</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/invertebrates">Invertebrates</a></li>
       <li><a href="/info/crustaceans">Crustaceans</a></li>
       <li><a href="/info/mollusks">Mollusks</a></li>
       <li><a href="/info/insects">Insects</a></li>
       <li><a href="/info/spiders">Spiders</a></li>
       <li><a href="/info/worms">Worms</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/plants">Plants</a></li>
       <li><a href="/info/flowering_plants">Flowering Plants</a></li>
       <li><a href="/info/trees">Trees</a></li>
       </ul>
       <ul>
       <li><a href="/info/fungi">Fungi</a></li>
       <li><a href="/info/mushrooms">Mushrooms</a></li>
       <li><a href="/info/molds">Molds</a></li>
       </ul>
       </li>
       <li>
       <ul>
       <li><a href="/info/bacteria">Bacteria</a></li>
       </ul>
       <ul>
       <li><a href="/info/algae">Algae</a></li>
       </ul>
       <ul>
       <li><a href="/info/protists">Protists</a></li>
       </ul>
       <ul>
       <li><a href="/info/archaea">Archaea</a></li>
       </ul>
       <ul>
       <li><a href="/info/viruses">Viruses</a></li>
       </ul>
       </li>
       </ul>
       <div class="partners">
       <h6><a href="http://www.biodiversitylibrary.org/">Biodiversity Heritage Library</a></h6>
       <p>Visit the Biodiversity Heritage Library</p>
       </div>
       <ul class="social_media">
       <li><a href="http://twitter.com/#!/EOL" class="twitter" rel="nofollow">Twitter</a></li>
       <li><a href="http://www.facebook.com/encyclopediaoflife" class="facebook" rel="nofollow">Facebook</a></li>
       <li><a href="http://www.flickr.com/groups/encyclopedia_of_life/" class="flickr" rel="nofollow">Flickr</a></li>
       <li><a href="http://www.youtube.com/user/EncyclopediaOfLife/" class="youtube" rel="nofollow">YouTube</a></li>
       <li><a href="http://pinterest.com/eoflife/" class="pinterest" rel="nofollow">Pinterest</a></li>
       <li><a href="http://vimeo.com/groups/encyclopediaoflife" class="vimeo" rel="nofollow">Vimeo</a></li>
       <li><a href="//plus.google.com/+encyclopediaoflife?prsrc=3" class="google_plus" rel="publisher"><img alt="&lt;span class=" translation_missing title="translation missing: en.layouts.footer.google_plus">Google Plus" src="//ssl.gstatic.com/images/icons/gplus-32.png" /&gt;</a></li>
       </ul>
       </div>
       <div class="questions">
       <h6>Tell me more</h6>
       <ul>
       <li><a href="/info/about_biodiversity">What is biodiversity?</a></li>
       <li><a href="/info/species_concepts">What is a species?</a></li>
       <li><a href="/info/discovering_diversity">How are species discovered?</a></li>
       <li><a href="/info/naming_species">How are species named?</a></li>
       <li><a href="/info/taxonomy_phylogenetics">What is a biological classification?</a></li>
       <li><a href="/info/invasive_species">What is an invasive species?</a></li>
       <li><a href="/info/indicator_species">What is an indicator species?</a></li>
       <li><a href="/info/model_organism">What is a model organism?</a></li>
       <li><a href="/info/contribute_research">How can I contribute to research?</a></li>
       <li><a href="/info/evolution">What is evolution?</a></li>
       </ul>
       </div>
       </div>
       </div>
       
       
       </div>
       <script src="/assets/head.load.min.js" type="text/javascript"></script>
       </body>
       </html>
       
       to have at least 1 element matching "div#iucn_status a", found 0.
     Shared Example Group: "taxon overview tab" called from ./spec/features/taxa_page_spec.rb:267
     # ./spec/features/taxa_page_spec.rb:101:in `block (3 levels) in <top (required)>'

Progress: |===============================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071618265831224471.html

  47) Taxa page community tab it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Community - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Community\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\n\n\n\n\nOverview\nDetail\nData\n14 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\n\n\n\n\n\n\n\n\nCommunities\n\n\nCollections\n\n\nCurators\n\n\n\n\n\nCommunities\nCommunities are groups of EOL members who come together to share their interests and expertise. EOL communities are organized around one or more EOL collections, and offer members a way to focus on topics of common concern. More information on EOL communities, including instructions for creating your own, is available on the help page.\n\n\n\nBelongs to 0 Communities\n\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nLogin or Create Account\nBecome part of the EOL community!\nJoin EOL now\n\nAlready a member?\nSign in\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:368
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |=================================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071618533243362660.html

  48) Taxa page resources when taxon has all expected data - taxon_concept it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Resources - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Resources\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\nAdd a link\nAdd an article\n\n\n\n\n\n\nOverview\nDetail\nData\n14 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\n\n\n\n\n\n\n\n\nAbout Resources\n\n\nPartner links\n\n\nEducation resources\n\n\n\n\n\nLinks To External Resources\n\nWe welcome you to provide links to third-party websites that relate to this organism or group of organisms. Examples include websites offering identification keys, news stories, blogs, as well as education and citizen science resources.\n\nAdd a link\n\nNote—all links are subject to EOL's Terms of Use and review by curators.If you have questions regarding a resource you would like to link to EOL, please contact us.\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nLogin or Create Account\nBecome part of the EOL community!\nJoin EOL now\n\nAlready a member?\nSign in\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:274
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |=================================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071618566230652701.html

  49) Taxa page names when taxon has all expected data - taxon_concept it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Classifications - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Classifications\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\n\n\n\n\nOverview\nDetail\nData\n14 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\n\n\n\n\n\n\n\n\nScientists aim to describe a single 'tree of life' that reflects the evolutionary relationships of living things. However, evolutionary relationships are a matter of ongoing discovery, and there are different opinions about how living things should be grouped and named. EOL reflects these differences by supporting several different scientific 'classifications'. Some species have been named more than once. Such duplicates are listed under synonyms. EOL also provides support for common names which may vary across regions as well as languages.\n\n\n\n\n3 classifications\n\n\n3 related names\n\n\n6 common names\n\n\n2 synonyms\n\n\n\n\n\n\n marks the preferred classification for this taxon.\n\n\nRecognized By\nRank\nClassification\n\n\nCatalogue of Life\n\nview in classification\n\n\nSpecies\n\n\nDignissimosii inutfc L. \n\nFugais utharumatvctsty A. Ankundinx\n\n\n\n\n\nCatalogue of Life\n\nview in classification\n\n\nSpecies\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n\n\n\n\n\nCatalogue of Life\n\nview in classification\n\n\n\n\n\n\nSome unused name\n\n\n\n\nShow 1 other non-browsable classification\n\n\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nLogin or Create Account\nBecome part of the EOL community!\nJoin EOL now\n\nAlready a member?\nSign in\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:327
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |===================================================================================================================
"should show the concepts preferred name style and " failed. Page saved to /home/ba/work/eol/tmp/capybara/capybara-201602071619132000980688.html

  50) Taxa page details when taxon has all expected data - taxon_concept it should behave like taxon name - taxon_concept page should show the concepts preferred name style and 
     Failure/Error: expect(page).to have_content(@taxon_concept.entry.name.ranked_canonical_form.string)
       expected there to be content "Minuseli ullameoc var. tsty" in "Cromulent Quiiurealiatsty - Fugais utharumatvctsty A. Ankundinx - Details - Encyclopedia of Life\n\n\n\n\n\n\n\n\nFugais utharumatvctsty A. Ankundinx\n &mdash; Details\n\n\nCromulent Quiiurealiatsty\nlearn more about names for this taxon\n\n\n\n\n\n\nAdd to a collection\n\n\n\nAdd a link\nAdd an article\n\n\n\n\n\n\nOverview\nDetail\nData\n15 Media\n0 Maps\nNames\nCommunity\nResources\nLiterature\nUpdates\nWorklist\n\n\n\n\n\n\n\nTable of Contents\n\nOverview\nBrief Summary\n\n\ntest toc item 2\n\n\ntest toc item 3\n\n\nResources\nPartner links\nEducation resources\nLiterature\nLiterature references\nBiodiversity Heritage Library\n\n\n\n\n\nOverview\n\n\n\nLearn more about this article\n\n\nThis is a test Overview, in all its glory\n\n\n\nA published visible reference for testing.\n\n\n\nA published visible reference with a DOI identifier for testing.\n \n10.12355/foo/bar.baz.230 \n\n\n\nA published visible reference with a URL identifier for testing.\n \nsome/url.html \n\n\n\nA published visible reference with an invalid identifier for testing.\n\n\n\n\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\nTrusted\n\n\n\nArticle rating\nfrom 0 people\n\n\nDefault rating: 2.5 of 5\n\n\n\n\n\n\nsee 1 comment for this article or rate it\n•\nshow in Overview\n\n\n\n\nBrief Summary\n\n\nLearn more about this article\n\n\nThis is a test brief summary.\n\n\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\nTrusted\n\n\n\nArticle rating\nfrom 0 people\n\n\nDefault rating: 2.5 of 5\n\n\n\n\n\n\nsee 1 comment for this article or rate it\n\n\n\n\n\ntest toc item 2\n\n\n\nLearn more about this article\n\n\nAccusantium est omnis quis. Itaque repellat ea aut voluptate delectus magni. Optio consectetur sit similique eum voluptatem eius. Voluptas et eius autem ea. Natus velit corrupti aliquid vitae alias minima.\n\n\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\nTrusted\n\n\n\nArticle rating\nfrom 0 people\n\n\nDefault rating: 2.5 of 5\n\n\n\n\n\n\nsee 1 comment for this article or rate it\n•\nshow in Overview\n\n\n\n\n\ntest toc item 3\n\n\n\nLearn more about this article\n\n\nCumque sapiente est accusantium aut sunt. Enim magni in quae voluptas dolorum. Officia ea aut rerum.\n\n\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\nTrusted\n\n\n\nArticle rating\nfrom 0 people\n\n\nDefault rating: 2.5 of 5\n\n\n\n\n\n\nsee 1 comment for this article or rate it\n•\nshow in Overview\n\n\n\n\n\nLearn more about this article\n\n\nQuia et ducimus aut eius officiis rerum quos. Dolore minima velit quas qui velit. Quaerat minus minima voluptatem maiores ut.\n\n\n\n\n\n\n\n© Someone\n\n\n\n\n\n\n\nTrusted\n\n\n\nArticle rating\nfrom 0 people\n\n\nDefault rating: 2.5 of 5\n\n\n\n\n\n\nsee 1 comment for this article or rate it\n•\nshow in Overview\n\n\n\n\n\n\n\n\n\nDisclaimer\nEOL content is automatically assembled from many different content providers. As a result, from time to time you may find pages on EOL that are confusing.\nTo request an improvement, please leave a comment on the page. Thank you!\n\n\n\n\n\n\n\n\n\nIntroducing TraitBank: search millions of data records on EOL   •   Learn more   •   Search data\n\n\n\n\nEncyclopedia of Life\n\nGlobal Navigation\n\nEducation\n\n\nHelp\n\n\nWhat is EOL?\n\n\nEOL News\n\n\n\n\n\n\n\nEnglish\n\n\n\nEnglish\n\n\nFrançais\n\n\nEspañol\n\n\nالعربية\n\n\n\n\nSearch the site\nSearch EOL\n\n\n\n\n\nAccount Information\n1 comment\n0 notifications\n\n\nAidbi\n\nProfile\nCurators\nSign Out\n\n\n\n\n\n\n\nSite information\n\n\nAbout EOL\nWhat is EOL?\nWhat is TraitBank?\nThe EOL Blog\nEducation\nStatistics\nGlossary\nPodcasts\nCiting EOL\nHelp\nTerms of Use\nContact Us\n\n\nLearn more about\n\nAnimals\nMammals\nBirds\nAmphibians\nReptiles\nFishes\n\n\nInvertebrates\nCrustaceans\nMollusks\nInsects\nSpiders\nWorms\n\n\nPlants\nFlowering Plants\nTrees\nFungi\nMushrooms\nMolds\n\n\nBacteria\nAlgae\nProtists\nArchaea\nViruses\n\n\nBiodiversity Heritage Library\nVisit the Biodiversity Heritage Library\n\nTwitter\nFacebook\nFlickr\nYouTube\nPinterest\nVimeo\nGoogle Plus\" src=\"//ssl.gstatic.com/images/icons/gplus-32.png\" />\n\n\nTell me more\nWhat is biodiversity?\nWhat is a species?\nHow are species discovered?\nHow are species named?\nWhat is a biological classification?\nWhat is an invasive species?\nWhat is an indicator species?\nWhat is a model organism?\nHow can I contribute to research?\nWhat is evolution?\n\n\n\n\n\n\n"
     Shared Example Group: "taxon name - taxon_concept page" called from ./spec/features/taxa_page_spec.rb:301
     # ./spec/features/taxa_page_spec.rb:214:in `block (3 levels) in <top (required)>'

Progress: |=================================================================================================================================
  51) Taxa::NamesController POST names properly mocked expires taxon
     Failure/Error: expect(controller).to have_received(:expire_taxa).with([taxon_concept.id])
       (#<Taxa::NamesController:0x000000139e75b0>).expire_taxa([1])
           expected: 1 time with arguments: ([1])
           received: 0 times with arguments: ([1])
     # ./spec/controllers/taxa/names_controller_spec.rb:90:in `block (4 levels) in <top (required)>'

Progress: |=================================================================================================================================
  52) Taxa::NamesController POST names properly mocked does not flash an error
     Failure/Error: expect(flash[:error]).to be_blank
       expected blank? to return true, got false
     # ./spec/controllers/taxa/names_controller_spec.rb:95:in `block (4 levels) in <top (required)>'

Progress: |=======================================================================================================================================
  53) DataSearchHelper#data_search_results_summary with results for "foo" and a taxon filter reminds us it's searching in a clade
     Failure/Error: expect(helper.data_search_results_summary).to include(I18n.t(:searching_within_clade,
       expected "" to include "within <a href=\"http://test.host/pages/%23%5BRSpec::Mocks::Mock:0x8cb57fc%20@name=TaxonConcept(id:%20integer,%20supercedure_id:%20integer,%20split_from:%20integer,%20vetted_id:%20integer,%20published:%20integer)%5D/overview\">rawr</a>"
     # ./spec/helpers/data_search_helper_spec.rb:45:in `block (4 levels) in <top (required)>'

Progress: |=======================================================================================================================================
  54) DataSearchHelper#data_search_results_summary with results for "foo" and no filter counts results
     Failure/Error: expect(helper.data_search_results_summary).to include(I18n.t(:count_results_for_search_term,
       expected "" to include "3 results for <em>foo</em>"
     # ./spec/helpers/data_search_helper_spec.rb:29:in `block (4 levels) in <top (required)>'

Progress: |==============================================================================================================================================
  55) Name should identify surrogate names
     Failure/Error: name.is_surrogate_or_hybrid?.should == true
       expected: true
            got: false (using ==)
     # ./spec/models/name_spec.rb:77:in `block (3 levels) in <top (required)>'
     # ./spec/models/name_spec.rb:36:in `each'
     # ./spec/models/name_spec.rb:36:in `block (2 levels) in <top (required)>'

Progress: |==================================================================================================================================================

P
  57) TaxonConcept should know when to should_show_clade_range_data
     Failure/Error: expect(tc.should_show_clade_range_data).to eq(true)
       
       expected: true
            got: false
       
       (compared using ==)
     # ./spec/models/taxon_concept_spec.rb:762:in `block (2 levels) in <top (required)>'

