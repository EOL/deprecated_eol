# Read "raw" output (via the TaxonData class) from our triplestore and convert
# them to (AR::B) Traits. NOTE: you _probably_ want to run this on master, since
# it will be creating a LOT of stuff; thus, if you care about the returned
# values, you may not find them on the slave...
#
# Example of an array element from input data:
#
#{ :attribute=>
#  #<RDF::URI:0x2fe2c50(http://eol.org/schema/terms/TypeSpecimenRepository)>,
#  :value=>
#  #<RDF::URI:0x2fe2638(http://biocol.org/urn:lsid:biocol.org:col:34871)>,
#  :life_stage=>#<RDF::URI:0x2fe2548(http://eol.org/schema/terms/ovigerous)>,
#  :sex=>#<RDF::URI:0x2fe2430(http://purl.obolibrary.org/obo/PATO_0000383)>,
#  :data_point_uri=>
#  <RDF::URI:0x2fe22dc(http://eol.org/resources/891/measurements/foo)>,
#  :graph=>#<RDF::URI:0x2fe20d4(http://eol.org/resources/891)>,
#  :taxon_concept_id=>#<RDF::URI:0x2fe1f80(http://eol.org/pages/3007084)> }
class SparqlToTraits
  attr_reader :traits, :contents
  def initialize(data)
    # TODO:
    uris = SparqlToKnownUris.new.uris
    node_lookup = {}
    # Need to load statistical method separately? I'd rather not, and instead
    # add it to the sparql query... Also units.
    attributes = data.map do |hash|
      { traitbank_uri: hash[:data_point_uri].to_s,
        predicate_id: KnownUri.uri(hash[:attribute].to_s).id,
        sex_id: KnownUri(hash[:sex].to_s, :value).id,
        lifestage_id: KnownUri(hash[:life_stage].to_s, :value).id,
        stat_method_id: TODO,
        units_id: TODO
      }
      node_lookup[hash[:data_point_uri].to_s] = {
        resource_id: hash[:graph].to_s.split('/').last.to_i,
        page_id: hash[:taxon_concept_id].to_s.split('/').last.to_i
      }
    end
    resource =
    @traits = TODO...
    contents = @traits.map do |trait|
      {
        item_type: "Trait",
        item_id: trait.id,
        node_id: TODO - need to Look them up
      }
    end
    @contents = TODO...
  end
end
