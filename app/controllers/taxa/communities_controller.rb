class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_concept

  def show
    @curators = @taxon_concept.acting_curators
    current_user.log_activity(:viewed_taxon_concept_community_curators, :taxon_concept_id => @taxon_concept.id)
  end

  def collections
    @collections = @taxon_concept.collections.select{ |c| !c.watch_collection? }
    current_user.log_activity(:viewed_taxon_concept_community_collections, :taxon_concept_id => @taxon_concept.id)
  end

  def communities
    @communities = @taxon_concept.communities
    current_user.log_activity(:viewed_taxon_concept_community_communities, :taxon_concept_id => @taxon_concept.id)
  end

end
