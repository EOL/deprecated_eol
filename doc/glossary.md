# Glossary:

**denormalization:**
Ruby and PHP code (they hand things off to one another) which re-arranges what
shows up where on the site. If you're supposed to see something on a particular
page and you don't, it's *usually* because this didn't run (or didn't work).

**harvest:**
PHP code which reads a resource file and puts it into the DB. You can't see it
on the site, yet. Traits are ported to the Old TraitBank (not visible on the
site).

**merge:**
Ruby code which looks at the relationships (see "relate") and then merges any
two matching taxa (the lower ID is always kept and the higher ID is superceded).

**new TB:**
New format of the data. More efficient (and simpler), and always visible on the
site.

**old TB:**
Old format of the data. Highly inefficient, not visible on the site.

**preview:**
Ruby code which relates, merges, and syncs the collection, then does a little
denormalization (only a little). Only the content partner (and maybe admins) can
see the data on the site.

**publish:**
Ruby code which shows all of the objects on EOL, relates, merges, ports traits,
and syncs the collection, then does all of the denormalization (except
TopImages).

**relate:**
Ruby code which looks at the names in a resource and compares them to all other
matching names. The results are stored in Solr. you can't see *any* of this on
the site, it's all behind the scenes.

**port:**
Moving TraitBank data from the old TB to the new TB. This is done as part of
publishing, but can also be run by itself on older resources, without
re-publishing the entire damn thing. :)
