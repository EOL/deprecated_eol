# The Services

The current intent (project "Tramea") is to break EOL up into several
interoperable (yet independently valuable) services, as follows. I imagine each
of these as a git repo under EOL.

## connectors

Scripts to pull information from remote sites to build DwCA files or
XML from them.

## content

Scripts to pull media from remote servers, put them in one place,
normalize them as needed, and serve them to the site.

## harvester

Scripts to read DwCA and XML files and store them in an intermediate,
normalized database. Also handles validation/parsing/error reporting. This is
where content partners and resources are created as well. It also "serves" old
versions of content via an API (so the site can render them as needed).

## publisher

Denormalizes data for rapid access, merges entries into "pages", keeps track of
curation, indexes data to enable searches. Perhaps not that last bit; that might
be part of the search code, below.

## website

Displays the published information, using denormalized data and indexes.
Handles users, collections, and the act of curating (though information about
this is passed back to the publisher). Also handles an API which mirrors the
functionality of the site (I do not see a benefit in separating the two of
these—there will be far too much overlap in the code). I do not expect to have
to use Solr in this codebase. Grr. That said, I'm still thinking about whether
this is better-served with SQL or a Triple-store. It's too early to say; I need
to run some experiments.

## search

A very light-weight service that handles full-text searching of all the data on
EOL, including traits, and including clade-based intelligence, but NOT including
geographic data. A robust API here, too. I don't expect API users to call
search.eol.org and api.eol.org in separate requests, so the service exposed by
this code would likely be "transparent" to the code on the site, sourced from a
single url. But the code would be separate, and this will likely have all of the
Solr stores.

## document_store

I'm rolling this idea around in my head, but this would be a (probably delayed)
representation of all of the data on EOL for super-rapid downloading of large
datasets. This is also where we would keep all of the scripts which populate
opendata.eol.org

## geo

Where we would import, analyze, store, serve, and allow search of all
geographic data.

# The Narrative

Thinking about what that might look like:

## connector

Only some resources need a connector, but those start here: a script mines the
data from the host site periodically and keeps it here for the harvester to pick
up when it's ready. This codebase differs from the existing connectors in that
the code itself is more generalized, with as many decisions as possible put into
the database, rather than the code—as soon as a new "type" of data conversion is
discovered, it is generalized and turned into a transformation option in the
database, to be (possibly) re-used (and/or refined) for another project later.

## harvester, part 1

A curator (or a partner) would create a resource associated with a partner
account. That specifies a harvest source (which could be a connector) and
frequency, and allows a force harvest.

## media

When harvesting runs, this codebase sends a batch request to the media code,
something like:

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
request). The files will be pre-processed as needed (e.g.: images will have
various thumbnails created, and converted to JPG). The resulting files will end
up available somewhere like this:

  http://content.eol.org/sites/1/images/34589_80_80.jpg

...The "images" comes from type.downcase.pluralize, of course.

## harvester, part 2

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
publishing codebase. The publish/preview code does many things:

(Note: "content" here includes names.)

* pull over all of the data from this harvest, in three buckets: new (all
  fields), removed (just IDs), and updated (just IDs and deltas)
* handle new data: if this is a preview, insert with "preview_new" flag (which
  is not visible to non-curators, unless you're associated with the partner);
  create indexes; update traitbank
* new Nodes are handled separately and specially: we attempt to match them to
  existing pages; any pages to which nodes are appended are checked for new
  preferred nodes; update traitbank as needed for those
* build associations for the new content
* handle removed data: if this is a preview, set "preview_remove" flag; if this
  is a publish, flag as "deleted"; remove indexes; update traitbank; check
  associated Pages for preferred names being removed and for no remaining nodes
* handle updates: if this is a preview, just add the delta field; if this is a
  publish, apply the delta; update indexes (where possible, using both old and
  new keywords); check associations for changes (this should be rare); update
  indexes; update traitbank
* denormalize the hierarchy (where not stale) for quick retrieval of ancestors
  (and children)
* kick off a search process to reindex everything
* study the images for pages and makes sure they're in the best order
* study the table of contents for data objects and pages
* create the associations between contents and pages
* update the resource (i.e.: last_published_at, etc)
* kick off an opendata process to build contributions file and update pages,
  names, contents, etc.

## website

Visibility:
* All content is visible to users associated with the source partner
* All non-"deleted" content is visible to curators
* All "visible", non-"preview_new" content is visible to non-curators
