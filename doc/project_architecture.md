The current intent (project "Tramea") is to break EOL up into several
interoperable (yet independently valuable) services, as follows. I imagine each
of these as a git repo under EOL.

# connectors

Scripts to pull information from remote sites to build DwCA files or
XML from them.

# content

Scripts to pull media from remote servers, put them in one place,
normalize them as needed, and serve them to the site.

# harvester

Scripts to read DwCA and XML files and store them in an intermediate,
normalized database. Also handles validation/parsing/error reporting. This is
where content partners and resources are created as well. It also "serves" old
versions of content via an API (so the site can render them as needed).

# publisher

Denormalizes data for rapid access, merges entries into "pages", keeps track of
curation, indexes data to enable searches. Perhaps not that last bit; that might
be part of the search code, below.

# site

Displays the published information, using denormalized data and indexes.
Handles users, collections, and the act of curating (though information about
this is passed back to the publisher). Also handles an API which mirrors the
functionality of the site (I do not see a benefit in separating the two of
these—there will be far too much overlap in the code). I do not expect to have
to use Solr in this codebase. Grr. That said, I'm still thinking about whether
this is better-served with SQL or a Triple-store. It's too early to say; I need
to run some experiments.

# search

A very light-weight service that handles full-text searching of all the data on
EOL, including traits, and including clade-based intelligence, but NOT including
geographic data. A robust API here, too. I don't expect API users to call
search.eol.org and api.eol.org in separate requests, so the service exposed by
this code would likely be "transparent" to the code on the site, sourced from a
single url. But the code would be separate, and this will likely have all of the
Solr stores.

# document_store

I'm rolling this idea around in my head, but this would be a (probably delayed)
representation of all of the data on EOL for super-rapid downloading of large
datasets. This is also where we would keep all of the scripts which populate
opendata.eol.org

# geo

Where we would import, analyze, store, serve, and allow search of all
geographic data.

---

Thinking about what that might look like:

Work would start at the harvester, where a curator (or a partner) would create a
resource associated with a partner account. That specifies a harvest source
(which could be a connector, in which case that's where the process starts) and
frequency, and allows a force harvest. When harvesting runs, this codebase sends
a batch request to the media code, something like:

{
  site_id: 1,
  resource_id: 96,
  contents: [
    { id: 34589, type: "Image",
      source_url: "http://some.cool.site/images/kdfho-123909.png" },
    { id: 34591, type: "Image",
      source_url: "http://some.cool.site/images/wupwe-882340.png" }
  ]
}

...Those source_urls would be downloaded. Errors would be stored in a special
table (you can request errors for a given site_id/content_id as another API
request). The files will be pre-processed as needed (e.g.: images will have various thumbnails created, and converted to JPG). The resulting files will end up available somewhere like this:

  http://content.eol.org/sites/1/images/34589_80_80.jpg

...The "images" comes from type.downcase.pluralize, of course.

The results from the harvest are in a highly normalized form, but remain pretty
flexible (ie: we're not bending over backwards here to parse all types of
credits—we just store those as json). Any kind of "thinking about" the data that
can be avoided here is: we're just getting the file parsed and into a database,
where it can be served quickly for other services.

I think perhaps that these data are actually on the same SQL server as the main
site, but in a different database. That way we can load things from one DB into
the other with a SQL command.

NOTE: there is no "resource collection" in Tramea. You can get that with a
query.

When the harvest is complete, it puts a publish (or preview) request into the
publishing codebase. This code does many things:

* mark all data (contents, entries, references, traits, etc) associated with
  the resource as stale. (This doesn't affect the _site_, just publishing code.)
* pull over all of the data from this harvest.
* update any data that's included in the new data, mark them as non-stale, keep
  track of old versions
* names that change will need to check with their associated pages to ensure
  they aren't affected
* insert any data that wasn't already here, mark as non-stale
* nodes are handled separately and specially: we attempt to match them to
  existing pages
* build associations for the new data (not sure if we need to update
  associations for updated data, but we should check them)
* denormalize the hierarchy (where not stale) for quick retrieval of ancestors
  (and children)
* delete stale data, including references in collections (maybe we notify
  owners about the removal)
* delete any pages that are now empty
* build/update pages in traitbank (this is complex, I'm skipping over it)
* kick off a search process to reindex everything
* study the images for pages and makes sure they're in the best order
* study the table of contents for data objects and pages
* create the associations between contents and pages
* update the resource (i.e.: last_published_at, etc)
* kick off an opendata process to build contributions file and update pages,
  names, contents, etc.
