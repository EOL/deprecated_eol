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
where content partners and resources are created as well.

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
EOL, including traits, and including clade-based inteligence, but NOT including
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
