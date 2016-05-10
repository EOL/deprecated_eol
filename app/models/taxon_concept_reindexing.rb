# This is the "long" method, using PHP, to reindex a taxon page, and is not
# allowed if there are too many descendants.
class TaxonConceptReindexing

  attr_reader :taxon_concept

  def self.reindex(taxon_concept, options={})
    TaxonConceptReindexing.new(taxon_concept, options).reindex
  end

  def initialize(taxon_concept, options={})
    @taxon_concept = taxon_concept
    @allow_large_tree = options[:allow_large_tree]
    @flatten = options[:flatten]
  end

  def reindex
    # TODO: RandomHierarchyImage should be scanned and updated, too!
    Rails.cache.delete(PageTraits.cache_key(@taxon_concept.id)) rescue nil
    @taxon_concept.disallow_large_curations unless @allow_large_tree # NOTE: this can raise an exception.
    begin
      @taxon_concept.lock_classifications
    rescue ActiveRecord::RecordNotUnique => e
      # Do nothing. It's okay; PHP will handle it.
    end
    CodeBridge.reindex_taxon_concept(@taxon_concept.id)
    Resque.enqueue(ClearTaxonMedia, @taxon_concept.id)
  end

end
