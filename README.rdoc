= Encyclopedia of Life

{<img src="https://badges.gitter.im/Join%20Chat.svg" alt="Join the chat at https://gitter.im/EOL/eol">}[https://gitter.im/EOL/eol?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge]

=== www.eol.org

== INTRODUCTION

Welcome to the Encyclopedia of Life project.  The bulk of the code needed to
run http://www.eol.org is written in Ruby on Rails and is made available to
anyone for re-use, repurposing or for improvement.  This is both an ambitious
project and an ambitious codebase and we are excited to share it with the open
source community.  The code has been under development since approximately
September 2007, but has undergone many revisions and updates from June
2008-December 2008.  There is much work to be done, both in adding new
features, and in the ongoing process of code refactoring and performance
improvements.  If you see something you like, share it with your colleagues and
friends and reuse it in your own projects.  If you see something you don't
like, help us fix it or join the discussion on GitHub.

== LICENSE

The full code base is released under the MIT License.  Details are available in
the "MIT-LICENSE.txt" file at the root of the code folder.

== GETTING STARTED

This is a big Rails project.  Some aspects of the installation below are
extensive and require multiple steps.  If you are not a Rails developer, we
suggest you first visit www.rubyonrails.org for more information on getting
started with Rails and then return to EOL when you are more familiar with the
framework.  The www.eol.org codebase probably shouldn't be the first Rails
project you've ever seen.

For seasoned Rails developers, you'll also notice the codebase does some mix
and matching--both restful controllers and regular controllers, for example.
We like the restful way of doing things and plan to move in that direction.
Some methods are monolithic, others are quite small.  ...and so on.  This
codebase has been developed by quite a mix of developers at various skill
levels and we apologize for the lack of homogeneity. Please bear with us as we
improve the code, slowly, over time.

Hint: start with the TaxonConcept model.  Most of the site's functionality
stems from there.

=== INSTALLATION

To get things up and running, these are the steps you need to take.  If you
actually run through this process, please update this list with any changes
you find necessary!

Note that many of these steps require root access on your machine.  You have
been warned and may need to run them as "sudo" on a Mac/Linux or as an
administrator on Windows (there, I acknowledged the existence of Windows).

=== FIRST THINGS FIRST

Things you need to do:

1. Setup Development Environment
2. Install Git
3. Install RVM
4. Get EOL Code Base
5. Install Ruby
6. Install MySQL
7. Install Gems
8. Setup Memcached
9. Install Virtuoso
10. Install Redis
11. Create EOL Databases
12. Start Solr
13. Populate EOL Databases
14. Get EOL Private Config
15. Run the EOL Rails Tests
16. Starting Your EOL Rails Server

=== Setup Development Environment

This will be platform specifc.

For MacOS X Mavericks (May, 2014):

First, install XCode from the App Store.  Once it is installed, launch it just
to accept the license.  Most of the rest of this will be run from the OSX
command line, which you can get to using the Terminal application which should
be in your Applications => Utilities folder.

From the Terminal program run:

  xcode-select --install

Next, install homebrew with:

  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

They above may ask some questions that need to be answered before running:

  brew doctor

=== Install Git

For MacOS X Mavericks (May, 2014):

  brew install git
  git config --global user.name "Your Full Name"
  git config --global user.email "Your Email Address”

For Ubuntu 12.04:
  sudo apt-get install git-core

=== Install RVM

This method works for both MacOS X and Ubuntu:

There are a couple different ways that work for this, but the simplest is:

  curl -L https://get.rvm.io | bash -s stable

Now CLOSE ANY OPEN SHELL WINDOWS you have in Terminal or other command-line
applications.

=== Get EOL Code Base

In a new Terminal window create the directory you want the top level directory
of the EOL code to go.  This will be $ROOT below.  I used:

  ROOT=~/git
  mkdir -p $ROOT
  cd $ROOT
  git clone https://github.com/EOL/eol.git

=== Install Ruby

For MAC OS X Mavericks (May, 2014):

To build the matching version of ruby you should look in the file
$ROOT/eol/.ruby-version.  As of May 2014 we are still using ruby-1.9.3-p392.
This is an older version that is no longer actively supported and it takes a
while to rebuild from scratch.  It also requires GCC 4.6 which you should be
able to install with:

  brew install gcc46

Then the following commands should do the trick:

  RUBY_VERSION=`cat $ROOT/eol/.ruby-version`
  rvm install $RUBY_VERSION

If the GCC 4.6 install didn't get picked up, you may need to do the install
more than once.

For Ubuntu 12.04:

  rvm install ruby
  rvm use ruby --default

=== Install MySQL

For MAC OS X Maverics (May, 2014):

Most versions of MySQL 5 should work.  As of May 2014, 5.6.1 was the current
stable release and works with this process.  To install the latest version run:

  brew install mysql

However, currently our production version is 5.1 and we are using 5.5 in some
of our systems so you may want to consider these older versions.

Once MySQL is installed, there are some additional recommended steps:

  unset TMPDIR
  mysql_install_db --verbose --user=`whoami` \
    --basedir="$(brew --prefix mysql)" --datadir=/usr/local/var/mysql \
    --tmpdir=/tmp
  mysql.server start
  mysql_secure_installation

This will ask you to provide a password that you will need for the
database.yml. To create the database.yml file in the config copy the handy
template to start with:

  cp $ROOT/eol/config/database.sample.yml $ROOT/eol/config/database.yml

Edit the database.yml and put the root database password in the devel_common
and tst_common blocks.

You may then want to set it up so the MySQL server launches at startup.
Under MacOSX Mavericks with MySQL 5.6.1 this works:

  ln -sfv /usr/local/opt/mysql/*.plist ~/Library/LaunchAgents
  launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist

For Ubuntu 12.04:

  sudo apt-get install mysql-server
  sudo apt-get install mysql-client

If the server is not running correctly, you can type the following command to start it:
  sudo /etc/init.d/mysql restart

=== Install Gems

For MAC OS X Maverics (May, 2014):

The capybara-webkit requires Qt.  This requires a separate install since it has
a "viral" opensource license - meaning that anything which incorporates the Qt
library (like capybara-webkit), must also be released under a similar license.
Capybara is a gem used in testing, so it and Qt are not typically incorporated
directly into tools that just use it for testing such as EOL.

  brew install qt

You should be able install the rest of the gems needed to get tests running
with:

  bundle install --without assets

The :assets group currently requires an older version of therubyracer gem which
indirectly depends on an old version of the C++ compiler and can be difficult
to get working.

For Ubuntu 12.04:

   rvm rubygems current

=== Setup Memcached

For MAC OS X Maverics (May, 2014):

Memcached is installed by default on MacOSX Mavericks.  Assuming this is true
on your machine, there is a .plist in $ROOT/eol/opt/org.eol.memcached.plist
that you can link into your home directory with:

  ln -s $ROOT/eol/opt/org.eol.memcached.plist ~/Library/LaunchAgents/
  launchctl load -w ~/Library/LaunchAgents/org.eol.memcached.plist

If you would rather manage it by hand, the command is:

  memcached -d -m 24 -p 11211

For Ubuntu 12.04:

You should have MySQL and PHP installed on the virtual server.

  sudo apt-get install mysql-server php5-mysql php5 php5-memcache

To start, install memcached via apt-get.

  sudo apt-get install memcached

The next step is to install php-pear, the repository that stores memcache.

  sudo apt-get install php-pear

If you do not have a compiler on your server, you can download build-essential in order to install memcache:

  sudo apt-get install build-essential

Finally use PECL (PHP Extension Community Library) to install memcache:

  sudo pecl install memcache

Once you have completed the installation of memcache with PECL on the VPS, add memcached to memcache.ini:

  echo "extension=memcache.so" | sudo tee /etc/php5/conf.d/memcache.ini

=== Install Virtuoso

For MAC OS X Maverics (May, 2014):

  brew install virtuoso

As of May 2014 this installs version 7.1.

Start Virtuoso in a separate Terminal window:

  cd /usr/local/Cellar/virtuoso/7.1.0/var/lib/virtuoso/db
  /usr/local/Cellar/virtuoso/7.1.0/bin/virtuoso-t +foreground

The foreground option is optional.  The full path to the executable is given
to deal with a potential issue when installing the PHP code base.

Back in your usual shell run:

  curl -i -d "INSERT {<http://demo.openlinksw.com/DAV/home/demo_about.rdf>
    <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>
    <http://rdfs.org/sioc/ns#User>}" \
    -u "dba:dba" -H "Content-Type: application/sparql-query" \
    http://localhost:8890/DAV/home/dba/upload

The response should be:
  HTTP/1.1 201 Created
  Server: Virtuoso/05.00.3023 (Win32) i686-generic-win-32  VDB
  Connection: Keep-Alive
  Content-Type: text/html; charset=ISO-8859-1
  Date: Fri, 28 Dec 2007 12:50:12 GMT
  Accept-Ranges: bytes
  MS-Author-Via: SPARQL
  Content-Length: 0

Next go to http://localhost:8890/ => Conductor => LinkedData (login with dba/dba) => Graphs (blue tab) => Graphs (white tab) and
check to see if there is a graph named http://localhost:8890%2FDAV%2Fdba%2Fupload
...if so, delete it.

Now run:

  isql 1111 dba dba

and at the SQL> prompt run:

  GRANT EXECUTE ON SPARUL_CLEAR TO "SPARQL"
  GRANT EXECUTE ON DB.DBA.SPARUL_DROP TO "SPARQL";
  GRANT DELETE ON DB.DBA.RDF_QUAD TO "SPARQL";
  GRANT EXECUTE ON DB.DBA.SPARQL_INSERT_DICT_CONTENT TO "SPARQL";
  GRANT EXECUTE ON DB.DBA.SPARQL_DELETE_DICT_CONTENT TO "SPARQL";
  quit;

For Ubuntu 12.04:

Rebuilding using Ubuntu packages:

  sudo apt-get install dpkg-dev build-essential

Download the Ubuntu source packages:

  sudo apt-get source virtuoso-opensource

Install the build-dependencies:

  sudo apt-get build-dep virtuoso-opensource

Start the package build using dpkg-buildpackage:

  dpkg-buildpackage -rfakeroot

Dpkg the debian files:

  sudo dpkg -i *.deb


=== Install Redis

For MAC OS X Maverics (May, 2014):

  brew install redis
  ln -sfv /usr/local/opt/redis/*.plist ~/Library/LaunchAgents
  launchctl load ~/Library/LaunchAgents/homebrew.mxcl.redis.plist

For Ubuntu 12.04:

Download build-essential

  sudo apt-get install build-essential

Download tcl:

  sudo apt-get install tcl8.5

Download the tarball from google code:

  wget http://download.redis.io/releases/redis-2.8.9.tar.gz

Untar it and switch into that directory:

  tar xzf redis-2.8.9.tar.gz
  cd redis-2.8.9

Proceed to with the make command:

  make
  make test
  sudo make install

To access the scripts move into the utils directory:

  cd utils

Run the Ubuntu/Debian install scripts:

  sudo ./install_server.sh

You can start and stop redist with these commands (the number depends on the port you set during the installation):

  sudo service redis_6379 start
  sudo service redis_6379 stop

You can then access the redis database by typing the following command:

  redis-ci

You can now have Redis installed and running. The prompt will look like this:

  redis 127.0.0.1:6379>

To set Redis to automatically at boot, run:

  sudo update-rc.d redis_6379 defaults

=== Get EOL Private Config

Currently this requires you have access to the private mbl-cli GitHub
community.  You must then create an SSH key and register it on GitHub as
described here: https://help.github.com/articles/generating-ssh-keys

We plan to at least make this step unnecessary to get the tests
passing.

  rake eol:site_specific repo=git@github.com:mbl-cli/eol-private.git

=== Create EOL Databases

You should now be ready to create the EOL databases with:

  rake db:create:all

=== Start Solr

  rake solr:start

This may popup a dialog asking you install Java which you should agree to.

=== Populate EOL Databases

You should now be ready to populate the EOL databases with:

  rake eol:db:rebuild
  rake eol:db:recreate RAILS_ENV=test
  rake eol:db:recreate RAILS_ENV=test_master
  rake scenarios:load NAME=bootstrap
  rake scenarios:load NAME=bootstrap RAILS_ENV=test

=== Run the EOL Rails Tests

You should now be able to run the Rails test suite with:

  rake

=== Starting Your EOL Rails Server

Run the following commands:

  rake eol:db:populate
  rails s

Go to http://localhost:3000 and (hopefully) see a relatively empty homepage.


== INFORMATION BELOW THIS POINT HAS NOT BEEN RECENTLY REVIEWED


=== Post Installation Conveniences

You *may* want to install zeus.  It makes many things run faster, but in our
experience it can be a bit buggy.  Not for the faint of heart.

=== Notes on SOLR

EOL requires Solr (a fast indexing engine) to run properly.  Solr is run using
Java, and the required JAR file is included with the EOL project's source code. Solr uses Virtuoso as data-store.
There is a rake task for starting (solr:start) and stopping (solr:stop) the
Solr server.  Solr is used extensively throughout the code for relating
objects, so the entire codebase requires Solr to run.

To remove your Solr data (if it's become corrupt or the like):

  rake solr:stop
  rm -R solr/solr/data/*/index
  rm -R solr/solr/data/*/spellchecker
  rake solr:start
  rake solr:build

To re-build your indexes for Solr searching (up to 100 TaxonConcepts), run the
command:

  rake solr:rebuild_all

Note that this command first deletes all existing entries, then adds entires
(max: 100) for each TaxonConcept in the development.  If you want to build
indexes based on the data in your test (or integration, or...) environments,
specify the RAILS_ENV:

  rake solr:build RAILS_ENV=test

As of this writing, we were running the following version:

  Solr Specification Version: 3.0.0.2011.06.21.10.13.24
  Solr Implementation Version: 3.3-2011-06-21_10-11-05 1137925 - hudson - 2011-06-21 10:13:24

=== TROUBLESHOOTING THE SEARCH FEATURE

To get to the solr UI, see:

  http://localhost:8983/solr/

...here, you will find links to each of the solr indexes and will be able to run custom queries and get basic info.

If you can't get running the search feature hopefully it's only because of Solr indexes missing.

Run the following commands:

  rake eol:db:rebuild
  rake eol:db:recreate RAILS_ENV=test
  rake eol:db:recreate RAILS_ENV=test_master

== TESTING

We're using RSpec for our testing (see the spec/ directory).  Run 'rake' to run the specs. More information is
available at https://www.relishapp.com/rspec/rspec-rails/v/2-11/docs

=== TROUBLESHOOTING

Possible error: "You haven't loaded the foundation scenario, and tried to build a TaxonConcept with no vetted id."

If you get this error, you may need to point your code to the correct version of mysqldump.

Create config/environments/local.rb (this will be ignored by revision control), and put this in it:

  $MYSQLDUMP_COMPLETE_PATH = '/usr/bin/mysqldump'

(But make sure that the path you use here is *really* a working version of mysqldump.)

=== LOGINS

The basic user types for testing are not readily available, but you can find their usernames from the console (the
passwords are always "test password"):

  User.admins.first.username    # Admin
  User.curators.first.username  # Curator
  Agent.first.user.username     # Content partner

If you need a basic user, it's recommended that you create one through the UI (or console).

== MULTI-DATABASE AND MASTER/SLAVE DATABASES SETUP

The site is built to allow for master/slave database read/write splitting for the core rails database and the
core "data" database.  The plugin involved in the use of multiple databases and read/write
splitting is:

  *masochism*:: used to split read/writes when using ActiveRecord
                (http://www.planetrubyonrails.org/tags/view/masochism)

Please note that EOL has made changes to both plugins to accomodate our own systems.

=== MULTIPLE DATABASES

New abstract class models are created which make connections to the other databases required, and then any
models which need to connect to the other databases are subclassed from the new abstract class.  In our case,
we have two abstract classes representing connections to the data database and the logging database:

  - SpeciesSchemaModel
  - LoggingModel

These extra two databases are referenced in the database.yml in the following way:

  - environment_data (e.g. development_data)
  - environment_logging (e.g. development_logging)

=== READ/WRITE SPLITTING

Read/write splitting is accomplished with the masochism plugin by adding two new database connections to the
config/database.yml file:

  - master_database (the master database connection for the core rails database)
  - master_data_database (the master database connection for the "data" database)

In addition there are new abstract classes representing a connection to each master database that can be
used to run direct SQL queries against the masters:

  - MasterDatabase   (for the core rails database)
  - SpeciesSchemaWriter  (for the species data database)

The logging database does not require read/write splitting since there is only a single server for this purpose.

To enable read/write splitting via ActiveRecord, include the following in the approriate environment.rb file
(e.g. config/environments/production.rb):

  config.after_initialize do
    ActiveReload::ConnectionProxy.setup!
    ActiveReload::ConnectionProxy.setup_for SpeciesSchemaWriter, SpeciesSchemaModel
  end

Note that you *must* also enable class caching for this to work (this is the default in production, but not in
development, which is important to note if you wish to test this functionality in development mode):

  config.cache_classes = true

Manually crafted SQL queries with SELECT statement will be redirected to slave while all other queries like in
the following example will be redirected to master:

  SpeciesSchemaModel.connection.execute("DELETE FROM data_objects WHERE id in (#{data_objects})")

You don't have to worry about master/slave databases in development mode unless you want to test your code
against splitting queries.  When in development, you could make the master_database and master_data_database
must point to the same place as development and development_data respectively.  Things should work even if
these entries are left out (since the master databases are only connected in a configuration entry in the
production environment) but it doesn't hurt if they are there.

== FINDING THINGS TODO

Spots in the code requiring some attention for refactoring, cleanup or further work are marked with a "TODO"
comment and sometimes with a level of priority.  You can quickly locate all these comments with your IDE, an
app like TextMate, or with a rake command:

  rake notes:todo

== CONFIGURATION SETTINGS LOAD ORDER

There are lots of configuration settings, and they load in the following order:

  1) config/environment.rb
  2) config/environments/[RAILS_ENV].rb
  3) config/environments/[RAILS_ENV]_eol_org.rb
  4) config/environment_eol_org.rb

== LOGGING

The logging model is intended to be thought of as a data mining system. A separate database is used to store
all log data, which must be defined in your config/database.yml file. (See sample file for naming.) Models and
operations tend to fall into two categories: dimensions and facts.  In short, dimensions represent collected
(primary) data. Facts are derived (secondary) caches of information which is more meaningful to the user.  Fact
table design is highly dependent on the user interface design, because we only need to generate facts if the
information will actually be shown.  For performance reasons regarding the expected database size, fact tables
are also intended to be highly denormalized, non-authoritative sources of information.

Location-based facts require the primary data to go through a geocoding process which requires an external web
service.  This process is thus performed asynchronously from the main site. Results of IP location lookups are
cached and reused whenever possible.  While IP location lookups are non-authoritative "best guesses", they
nevertheless provide meaningful information.

In production mode it is CRITICALLY important to understand the automated logging tasks before invoking them to
avoid deletion of precious data.  To develop logging features, run the following tasks in the given order to
populate your logging database with mock data...

  rake logging:clear                       # Deletes all logging-related records. (WARNING: NEVER run in production.)
  rake logging:dimension:mock THOUSANDS=2   # Creates 2,000 psedo-random mock log entries (a.k.a. primary data).
  rake logging:geocode:all                 # Performs geocoding on the primary data, using caches where possible.
  rake logging:fact:all                     # Derives secondary data from primary data.

...at this point you should see data in the graph pages of the web application. Alternatively, run the
following which does all of the above in one step....

  script/runner script/logging_mock

For cron jobs, you'll likely want to log all facts for a particular date range:

   rake logging:fact:today
   rake logging:fact:yesterday
   rake logging:fact:range FROM='01/15/2007' TO='12/19/2008'

== EXTERNAL LINK TRACKING

Any links to external sites that need to be tracked should use the following two helpers:

  external_link_to(text, url)
  external_link_to(image_tag(image), url)

Both will generate a link (with either the supplied text or the supplied image url) to the supplied URL.  The
link will be logged in the database, and if the $USE_EXTERNAL_LINK_POPUPS parameter is set to TRUE in the
environment.rb file, a javascript pop-up warning window is shown prior to following the link.  The following
additional parameters can be passed after the URL for both methods:

  +:new_window        => true or false+::
    determines if link appears in new browser window (defaults to true)
  +:show_only_if_link => true or false+::
    determines if image or text is shown if no URL was supplied (defaults to false)
  +:show_link_icon    => true or false+::
    determines if the external icon image is shown after the link (defaults to true for text links and false for
    image links)

For images, the following parameters can also be passed:

  +:alt   => 'value'+:: alt tag is set with the value passed
  +:title => 'value'+:: title tag is set with the value passed

Currently no reports are provided for external link tracking, all links are stored in the "external_link_logs"
in the logging database for later reporting.

== FRAGMENT CACHING

Fragment caching is enabled in the specific environment file (e.g. config/production.rb) and the storage
mechanism (i.e. memcached) must be set as well.

For memcached:

  config.cache_store = :dalli_store, '10.0.0.1:11211', '10.0.0.2:11211'

To enable caching:

  config.action_controller.perform_caching = true

All "static" pages coming out of the CMS are fragment cached and the home page cache is cleared each hour (or
as set in the $CACHE_CLEAR_IN_HOURS value set in the config/environment.rb file), using language as key to
enable multiple fragments.  The header and footer navigation of each page is also fragment cached on cleared at
the same time interval.  When changes are made in the admin interface, these caches are automatically cleared.

Names searches are cached by query type, language and vetted/non-vetted status.

Species pages are cached using the following attributes as keys (since each will cause a different species page
to be created).  Note that when logged in as an administrator or content partner, the pages are not cached and
are generated dynamically each time.

Variables for naming species page fragment caches:

  - taxon_id
  - language
  - curator level

Species page caches can be cleared by taxon ID by a CMS Site Administrator by logging into the admin console,
and going to "General Site Admin".  Clearing a species page cache automatically clears all of its ancestors as
well.

The following URLs can be used to trigger page expiration either manually in the browser or via a web service
call.  They only work if called from "allowed" IPs (i.e. as specified in configuration) as defined in the
application level method "allowed_request" (which returns TRUE or FALSE).

  /expire_all    # expire all non-species pages
  /expire_taxon/TAXON_ID  # expire specified taxon ID (and it's ancestors)
  /expire_taxa/?taxa_ids=ID1,ID2,ID3 # will expire a list of taxon IDs (and their unique ancestors) specified in
      the querystring (or post) parameter "taxa_ids" (separate by commas)
  /clear_caches # expire all fragment caches (if supported by data store mechanism)

From within the Rails applications, use the following application level methods:

  expire_all   # expire all non-species pages
  expire_taxon(taxon_ID)  # expire specified taxon id and ancestors (unless :expire_ancestors=>false is set)
  expire_taxa(taxon_ID_array)# expire specified array of taxon ID and unique ancestors (unless :expire_ancestors=>false
      is set)
  clear_all_caches # expire all fragment caches (everything!)

== ASSET PACKAGER (CSS and JS)

This is now using the asset_packager plugin, see details at http://synthesis.sbecker.net/pages/asset_packager

If you add a javascript include files and you want them included in the page, you must edit the
"config/asset_packager.yml" file and place them in the order you wish them to be loaded.  When running in
development mode, the JS and CSS are included separately each time. When running in production mode, assets are
included from packaged entities.  A rake task is used to combine and minify CSS and JS  referenced.  Note that
the order the JS files are listed in the config file is the order they are merged together and this order can
matter.

You must run this rake task each time the JS/CSS is updated to ensure the latest version is present when
running in production mode.  The minification process is very sensitive to missing semicolons, extra commas and
what not that are dealt with by modern browsers (not IE though...).  You have been warned - minification can
and will break your JS if you are not careful (watch those semicolons)!

To update/create the combined versions:

  rake asset:packager:build_all

In production, this rake command is run as part of the capistrano deploy script.

For testing purposes, you can force the minified/combined version to be referenced in your pages for a
particular environment by adding the following line to your "config/environments/development.rb" or
"config/environment.rb" file:

  Synthesis::AssetPackage.merge_environments = ["development", "production"]

== TAXON CONCEPT ATTRIBUTION NOTES

To get attribution for a given taxon concept ID:

1. Get TaxonConcept
   e.g.
     t = TaxonConcept.find(101)
2. Look at hierarchy_entry for that taxon (could be many)
   e.g.
     he_all = t.hierarchy_entries  OR  he = t.entry (for the default)
3. Look at the associated hierarchy (could be one of many if you get them all)
   e.g.
      h = he_all[0].hierarchy #   OR  h = he.hierarcy
      h.label
      h.agent.full_name
      h.agent.hompage
      h.agent.logo_cache_url
4. Look at the associated agents for the hierarchy_entry e.g.

     agents = he[0].agents  # OR  agents = he.agents
     agents.each {|agent| puts agent.full_name + " " + agent.homepage + " " + agent.logo_cache_url}

== What is a sitemap?
Sitemaps are an easy way for webmasters to inform search engines about pages on their sites that are available for crawling. In its simplest form, a Sitemap is an XML file that lists URLs for a site along with additional metadata about each URL (for example: when it was last updated) so that search engines can more intelligently crawl the site.

Web crawlers usually discover pages from links within the site and from other sites. Sitemaps supplement this data to allow crawlers that support Sitemaps to pick up all URLs in the Sitemap and learn about those URLs using the associated metadata. Using the Sitemap protocol does not guarantee that web pages are included in search engines, but provides hints for web crawlers to do a better job of crawling your site.

== How to add new links in sitemap?
Add the new link(s) in sitemap.rb file (located under config/sitemap.rb) and then update the sitemap to reflect these changes.
== Example: 
add "/new_page", priority: 1, lastmod: "2015-02-11T12:12:12+02:00"
this will create as follows:
<url>
   <loc>http://localhost:3000/new_page</loc>
   <lastmod>2015-02-11T12:12:12+02:00</lastmod>
   <priority>1.0</priority>
</url>

== How to update sitemap?

just run the rake task:
rake sitemap:refresh
by this command a new sitemap will be generated based on the urls supplied in the sitemap.rb file.

== CREATING A GOOGLE SITEMAP

To create Google SiteMap files in the correct format, run the following rake task for your requested environment:

  rake sitemap:create RAILS_ENV=production[,BASEURL="http://www.eol.org/pages/",BASEURL_SITEMAP="http://www.eol.org/sitemaps/",MAXPERFILE="50000",OUTPUTPREFIX="eol_sitemap",PRIORITY="1",CHANGEFREQ="monthly",LASTMOD="2009-03-01"]

All of the parameters in brackets are optional and have the default shown (except for 'lastmod' which defaults
to today).

The URLS placed into the site map file are based on 'BASEURL/XXX' where XXX is a valid published, trusted taxon
concept ID pulled from the specified environment. ...
