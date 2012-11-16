class CollectedTaxon

  class << self
    attr_accessor :includes, :selects
  end

  # This is more than is needed for non-anotated views, but allows us to use the same info for all views:
  @includes = [
    :taxon_concept_metric,
    { :preferred_common_names => [ :name, :language ] },
    { :preferred_entry => 
      { :hierarchy_entry => [ { :flattened_ancestors => { :ancestor => :name } },
        { :name => [ :canonical_form, :ranked_canonical_form ] } , :hierarchy, :vetted ] } },
    { :taxon_concept_exemplar_image => :data_object }
  ]

  @selects = {
    :taxon_concepts => '*',
    :taxon_concept_preferred_entries => '*',
    :taxon_concept_exemplar_images => '*',
    :taxon_concept_metrics => [ :taxon_concept_id, :richness_score ],
    :hierarchy_entries => [ :id, :rank_id, :name_id, :identifier, :hierarchy_id, :parent_id,
                            :published, :vetted_id, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
    :names => [ :id, :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
    :canonical_forms => [ :id, :string ],
    :hierarchies => [ :id, :agent_id, :browsable, :outlink_uri, :label ],
    :vetted => [ :id, :view_order ],
    :hierarchy_entries_flattened => '*',
    :ranks => '*',
    :data_objects => [ :id, :object_cache_url, :data_type_id, :guid, :published ]
  }

  attr_reader :taxon_concept
  attr_reader :taxon_concept_id

  def self.fetch(taxon_concept_id)
    CollectedTaxon.new(taxon_concept_id).fetch
  end

  def initialize(taxon_concept_id)
    @taxon_concept_id = taxon_concept_id
  end

  def fetch
    @taxon_concept = Rails.cache.fetch(TaxonConcept.cached_name_for("collected_taxon_#{taxon_concept_id}"),
                                       :expires_in => 1.week) do
      instance = TaxonConcept.find(taxon_concept_id)
      TaxonConcept.preload_associations(instance, CollectedTaxon.includes, :select => CollectedTaxon.selects)
      # TODO - this seems out of place:
      EOL::Solr::DataObjects.lookup_best_images_for_concepts([instance])
      instance.dup
    end
  end

  def delete
    Rails.cache.delete(TaxonConcept.cached_name_for("collected_taxon_#{taxon_concept_id}"))
  end

end
