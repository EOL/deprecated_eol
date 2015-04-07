# Read "raw" output (via the TaxonData class) from our triplestore and convert
# them to (AR::B) Traits. NOTE: you _probably_ want to run this on master, since
# it will be creating a LOT of stuff; thus, if you care about the returned
# values, you may not find them on the slave...
#
# Keys from input data (all values are either an RDF::URI or a literal, but can
# be missing entirely (if the value was nil)):
#
# { :attribute, :value, :life_stage, :sex, :data_point_uri, :graph,
# :taxon_concept_id, :unit_of_measure_uri }
class SparqlToTraits
  attr_reader :traits, :contents, :uris

  def initialize(data)
    @uris = SparqlToUris.new(data)
    @node_lookup = {}
    attributes = data.map do |hash|
      add_node_lookup(hash)
      attributes_from_hash(hash)
    end
    add_hierarchies_to_lookup
    # And we have to go through a second time to add associations:
    add_associations(attributes)
    @traits = Mysql::MassInsert.from_hashes(attributes, Trait)
    # This is a slower lookup; faster when you have a taxon concept id, but,
    # alas. We COULD do them one by one, but I think this would prove faster in
    # bulk. ...I think. Not really worth testing.
    @data_point_uris = DataPointUri.
      includes(:taxon_data_exemplars).
      where(uri: data.map { |d| d[:data_point_uri] })
    @exemplars = TaxonDataExemplar.where()
    content_hashes = @traits.map do |trait|
      content_attributes_from_trait(trait)
    end
    @contents = Mysql::MassInsert.from_hashes(content_hashes, Content)
  end

  def attributes_from_hash(hash)
    literal_value = nil
    value = grab(hash, :value)
    h = {
      traitbank_uri: grab(hash, :data_point_uri),
      predicate_id: uri_id(grab(hash, :attribute)),
      # TODO: Normalize units...
      value_id: uri_id(value),
      value_literal: value ? nil : hash[:value],
      sex_id: uri_id(grab(hash, :sex)),
      lifestage_id: uri_id(grab(hash, :life_stage)),
      stat_method_id: uri_id(grab(hash, :statistical_method)),
      # TODO: Normalize the gorram units.
      units_id: uri_id(grab(hash, :unit_of_measure_uri)),
      inverse_id: uri_id(grab(hash, :inverse_attribute))
    }
    if added_by_user?(hash)
      # We do have a user id, and the curation comes from a different model.
      # These are pretty rare, so I'm just going to look them up one by one,
      # here:
      h[:added_by_user_id] = UserAddedData.
        where(grab_id(hash, :data_point_uri)).
        pluck(:added_by_user_id).
        first # (there will only be one)
    end
    # NOTE: This is (intentionally) WRONG! We make it a TC id here; we really
    # want an HE ID, which is more flexible and gives us the right name that the
    # resource _actually_ used for the association. We'll fix it in
    # #add_associations...
    if hash.has_key?(:target_taxon_concept_id)
      h[:node_id] = grab(hash, :target_taxon_concept_id)
    end
    h
  end

  def add_associations(hashes)
    hashes.map do |hash|
      if hash.has_key?(:node_id)
        key = grab(hash, :data_point_uri)
        hash[:node_id] = HierarchyEntry.
          find_by_hierarchy_id_and_taxon_concept_id(
            @node_lookup[key][:hierarchy_id],
            hash[:node_id]
          ).try(:id)
        hash
      else
        hash
      end
    end
  end

  def uri_id(uri)
    @uris.find { |u| u.uri == uri }.try(:id)
  end

  def content_attributes_from_trait(trait)
    dpuri = @data_point_uris.find { |u| u.uri == trait.traitbank_uri }
    { item_type: "Trait",
      item_id: trait.id,
      # NOTE: Sadly, there is no (elegant) way to search by pairs of values,
      # so, yes, we have to look these up one by one. Shucks.
      node_id: HierarchyEntry.
        find_by_hierarchy_id_and_taxon_concept_id(
          @node_lookup[trait.traitbank_uri][:hierarchy_id],
          @node_lookup[trait.traitbank_uri][:page_id]
        ).try(:id),
      visible: dpuri.visible?,
      vetted: dpuri.vetted?,
      included: dpuri.included?,
      excluded: dpuri.excluded?
    }
  end

  private

  def add_node_lookup(hash)
    @node_lookup[grab(hash, :data_point_uri)] = {
      resource_id: grab_id(hash, :graph),
      page_id: grab_id(hash, :taxon_concept_id)
    }
    if added_by_user?(hash)
      # We don't have a resource id (the graph is a special one)
      @node_lookup[grab(hash, :data_point_uri)][:resource_id] = nil
    end
  end

  def added_by_user?(hash)
    hash[:graph] == Rails.configuration.user_added_data_graph
  end

  def add_hierarchies_to_lookup
    hierarchies = Hierarchy.select([:id, :resource_id]).where(
      resource_id: @node_lookup.values.map { |h| h[:resource_id] }.uniq
    )
    @node_lookup.each do |lookup|
      lookup[:hierarchy_id] =
        hierarchies.find { |h| h.resource_id = lookup[:resource_id] }
    end
  end

  # I wanted this to have a short name. It either gets a URI (As a string) or
  # returns nil.
  def grab(hash, key)
    if hash[key].is_a?(RDF::URI)
      hash[key].to_s
    else
      nil
    end
  end

  # i.e.: http://eol.org/pages/1234 -> 1234
  def grab_id(hash, key)
    s = grab(hash, key)
    return nil unless s.is_a?(String)
    s.split('/').last.to_i
  end
end
