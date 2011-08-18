class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_concept

  def show
    @curators = @taxon_concept.acting_curators
    @collections = @taxon_concept.collections.select{ |c| !c.watch_collection? }
    @communities = @taxon_concept.communities
    current_user.log_activity(:viewed_taxon_concept_communities, :taxon_concept_id => @taxon_concept.id)
  end

end
