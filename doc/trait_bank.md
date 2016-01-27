TraitBank
=========

Structure
---------

All "new format" data is stored in a single graph: <http://eol.org/traitbank>.

The "new format" for TB is roughly as follows:

page -> predicate -> trait
trait -> trait_predicate -> value
value -> meta_predicate -> meta_value

Definitions of those terms:

page: the URL to a page on EOL, e.g.: <http://eol.org/pages/>.

predicate: basically, the uri of a KnownUri. e.g.:
<http://purl.obolibrary.org/obo/OBA_0000056>. Note that one of these will be
<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, which you can ignore; the
value should always be "eol:page", and that triple is just to store the fact
that the page is really a page.  :)

trait: A unique identifier for a "cluster" of information, ultimately describing
a trait. These usually look something like
<http://eol.org/resources/1234/measurements/5678910>, and the "1234" should be
the resource that the file came from, and the 5678910 should be the ID used in
the resource file for that line of data. While this all sounds relatively
complicated: *it doesn't really matter*. This just needs to be a unique ID to
describe a bunch of trait data.

trait_predicate: the predicate used to describe some aspect of the trait. These
are *almost always* the uris of KnownUris. There are several specific
trait_predicates that you should be familiar with:

  <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>: the value of this will be
  "eol:trait", and is just used to store the fact that you're looking at a
  trait.

  <http://rs.tdwg.org/dwc/terms/lifeStage>: Stores the life stage of the trait.

  <http://rs.tdwg.org/dwc/terms/sex>: Stores the sex of the trait.

  <http://purl.org/dc/terms/source>: *There are two of these.* One of them will
  point to the resource that the data came from (this is for convenience). The
  other is "real" source information about the trait, e.g.: the original source
  that the trait was pulled from, like a scientific paper or textbook.

  <http://eol.org/schema/terms/statisticalMethod>: Stores the statistical method
  of the trait, e.g.: average, mean, etc.

  <http://rs.tdwg.org/dwc/terms/measurementValue>: *IMPORTANT:* The value!
  (q.v.)

value: Note that this could be any one of: a literal string, a number stored as
a string, a URI stored as a string (sigh), or a URI pointing to a cluster of
additional information, which will be read in with "meta_predicate"s attached to
it (q.v.). (In this last case, the value is a number with units.)

meta_predicate: when the "value" is a URI, it might have more triples associated
with the value as a subject. These triples have a meta_predicate, which at the
moment can only be <http://rs.tdwg.org/dwc/terms/measurementValue> or
<http://rs.tdwg.org/dwc/terms/measurementUnit>.

meta_value: The value associated with the meta_predicate; these MUST be
KnownUris or literals; they cannot be expressed as subjects themselves.

Class Examples
--------------

There are several classes you should be familiar with to use TB; I will express
these with examples:

# The data for a TaxonConcept page:
concept = TaxonConcept.find(1234)
data = PageTraits.new(concept.id)
data.categories # => An array of TocItem instances describing the TOC of the data.
data.glossary # => An array of KnownUri instances for ALL traits in the data, including predicates,
  # values, and meta values.
data.traits # => An array of Trait instances for the page.
data.traits_by_category(category) # => An array of Trait instances matching the TocItem instance of category.
trait = data.traits.first # => A single Trait instance, of course.
trait.point # => A DataPointUri instance.
trait.predicate_uri # => The KnownUri for the predicate, or an UnknownUri if one wasn't found.
trait.predicate_name # => The STRING for the predicate. Usually, this is the #name of a KnownUri.
trait.anchor # => A unique ID suitable for using as the ID in an HTML row.
trait.statistical_method? # => A boolean; does this trait have any statistical methods?
trait.trait.statistical_method_names # => An array of strings naming the statistical methods used.
trait.value_uri # => The KnownUri (or an UnknownUri) for the value.
trait.value_name # => The string for the value.
trait.comments # => An array of Comment instances.
trait.content_partner # => An instance of ContentPartner associated with the trait. Could be nil!
# Note that in a view, you can use the following helper on the trait instance to render it with all
# its ancilary information (sex, life stage, etc):
format_value(trait)
